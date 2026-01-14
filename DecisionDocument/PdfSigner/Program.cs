using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using iText.Kernel.Pdf;
using iText.Signatures;
using iText.Bouncycastle.X509;
using Org.BouncyCastle.X509;

namespace PdfSignerApp
{
    class Program
    {
        static int Main(string[] args)
        {
            Console.WriteLine("==========================================");
            Console.WriteLine("PDF Digital Signature Tool");
            Console.WriteLine("Uses Windows Certificate Store (PIV/CAC)");
            Console.WriteLine("==========================================");
            Console.WriteLine();

            if (args.Length == 0)
            {
                Console.WriteLine("Usage: PdfSigner.exe <input.pdf> [output.pdf]");
                Console.WriteLine();
                Console.WriteLine("Options:");
                Console.WriteLine("  --list    List available signing certificates");
                Console.WriteLine();
                return 1;
            }

            if (args[0] == "--list")
            {
                ListCertificates();
                return 0;
            }

            string inputPdf = args[0];
            string outputPdf = args.Length > 1 ? args[1] : GetOutputPath(inputPdf);

            if (!File.Exists(inputPdf))
            {
                Console.WriteLine($"Error: Input file not found: {inputPdf}");
                return 1;
            }

            try
            {
                // Get signing certificate from Windows store (includes smart cards)
                X509Certificate2? cert = SelectSigningCertificate();
                if (cert == null)
                {
                    Console.WriteLine("No certificate selected. Exiting.");
                    return 1;
                }

                Console.WriteLine();
                Console.WriteLine($"Selected: {cert.Subject}");
                Console.WriteLine();

                // Sign the PDF - Windows will prompt for PIN if smart card
                SignPdf(inputPdf, outputPdf, cert);

                Console.WriteLine();
                Console.WriteLine($"SUCCESS: Signed PDF saved to: {outputPdf}");
                return 0;
            }
            catch (CryptographicException ex)
            {
                Console.WriteLine();
                Console.WriteLine($"Cryptographic error: {ex.Message}");
                Console.WriteLine("This may occur if PIN entry was cancelled or the smart card was removed.");
                return 1;
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine($"Error: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner: {ex.InnerException.Message}");
                }
                return 1;
            }
        }

        static string GetOutputPath(string inputPath)
        {
            string dir = Path.GetDirectoryName(inputPath) ?? ".";
            string name = Path.GetFileNameWithoutExtension(inputPath);
            string ext = Path.GetExtension(inputPath);
            return Path.Combine(dir, $"{name}_signed{ext}");
        }

        static List<X509Certificate2> GetSigningCertificates()
        {
            var result = new List<X509Certificate2>();

            using var store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            store.Open(OpenFlags.ReadOnly);

            // Add all certificates from the personal store
            // We don't check HasPrivateKey here because that can trigger
            // smart card access and cause hangs
            foreach (var cert in store.Certificates)
            {
                result.Add(cert);
            }

            return result;
        }

        static void ListCertificates()
        {
            Console.WriteLine("Available signing certificates in Windows Certificate Store:");
            Console.WriteLine();

            var certs = GetSigningCertificates();

            if (certs.Count == 0)
            {
                Console.WriteLine("No signing certificates found.");
                Console.WriteLine();
                Console.WriteLine("If you have a PIV/CAC smart card inserted, ensure:");
                Console.WriteLine("  1. The card reader drivers are installed");
                Console.WriteLine("  2. The smart card middleware is configured");
                Console.WriteLine("  3. The certificate appears in certmgr.msc");
                return;
            }

            int index = 0;
            foreach (var cert in certs)
            {
                index++;
                Console.WriteLine($"[{index}] {cert.Subject}");
                Console.WriteLine($"    Issuer: {cert.Issuer}");
                Console.WriteLine($"    Expires: {cert.NotAfter:yyyy-MM-dd}");
                Console.WriteLine($"    Thumbprint: {cert.Thumbprint}");
                Console.WriteLine();
            }
        }

        static X509Certificate2? SelectSigningCertificate()
        {
            var certs = GetSigningCertificates();

            if (certs.Count == 0)
            {
                Console.WriteLine("No certificates found in Windows Certificate Store.");
                Console.WriteLine();
                Console.WriteLine("Ensure your smart card is inserted and recognized by Windows.");
                return null;
            }

            if (certs.Count == 1)
            {
                // Only one cert available - use it automatically
                Console.WriteLine($"Using certificate: {certs[0].Subject}");
                return certs[0];
            }

            // Multiple certs - let user choose
            Console.WriteLine("Available certificates:");
            Console.WriteLine();

            int index = 0;
            foreach (var cert in certs)
            {
                index++;
                // Extract just the CN for cleaner display
                string displayName = cert.Subject;
                if (displayName.StartsWith("CN="))
                {
                    int comma = displayName.IndexOf(',');
                    if (comma > 0)
                        displayName = displayName.Substring(3, comma - 3);
                    else
                        displayName = displayName.Substring(3);
                }
                Console.WriteLine($"  [{index}] {displayName}");
                Console.WriteLine($"      Expires: {cert.NotAfter:yyyy-MM-dd}");
            }

            Console.WriteLine();
            Console.Write($"Select certificate [1-{certs.Count}]: ");

            string? input = Console.ReadLine();
            if (int.TryParse(input, out int choice) && choice >= 1 && choice <= certs.Count)
            {
                return certs[choice - 1];
            }

            Console.WriteLine("Invalid selection.");
            return null;
        }

        static void SignPdf(string inputPath, string outputPath, X509Certificate2 cert)
        {
            Console.WriteLine("Signing PDF...");
            Console.WriteLine("(Windows Security will prompt for your PIN if using a smart card)");

            // Convert .NET cert to iText-wrapped BouncyCastle cert
            var bcCert = new X509CertificateParser().ReadCertificate(cert.RawData);
            var wrappedCert = new X509CertificateBC(bcCert);
            var chain = new iText.Commons.Bouncycastle.Cert.IX509Certificate[] { wrappedCert };

            // Create external signature using Windows CNG (triggers PIN dialog)
            var externalSignature = new X509Certificate2Signature(cert, "SHA256");

            using var reader = new PdfReader(inputPath);
            using var outputStream = new FileStream(outputPath, FileMode.Create, FileAccess.Write);

            var signer = new iText.Signatures.PdfSigner(reader, outputStream, new StampingProperties());

            // Set signature field name
            signer.SetFieldName("Signature1");

            // Perform the signature - this triggers the PIN dialog for smart cards
            signer.SignDetached(externalSignature, chain, null, null, null, 0,
                iText.Signatures.PdfSigner.CryptoStandard.CMS);
        }
    }

    /// <summary>
    /// External signature implementation using Windows Certificate Store.
    /// This bridges iText's signature interface with .NET's X509Certificate2.
    /// When accessing a smart card private key, Windows CNG automatically
    /// displays the PIN prompt dialog.
    /// </summary>
    public class X509Certificate2Signature : IExternalSignature
    {
        private readonly X509Certificate2 _certificate;
        private readonly string _hashAlgorithm;

        public X509Certificate2Signature(X509Certificate2 certificate, string hashAlgorithm)
        {
            _certificate = certificate;
            _hashAlgorithm = hashAlgorithm;
        }

        public string GetDigestAlgorithmName() => _hashAlgorithm;

        public string GetSignatureAlgorithmName()
        {
            var key = _certificate.GetRSAPrivateKey();
            if (key != null) return "RSA";

            var ecKey = _certificate.GetECDsaPrivateKey();
            if (ecKey != null) return "ECDSA";

            throw new InvalidOperationException("Unsupported key algorithm");
        }

        public ISignatureMechanismParams? GetSignatureMechanismParameters() => null;

        public byte[] Sign(byte[] message)
        {
            // This is where Windows CNG prompts for PIN when accessing
            // a smart card private key

            var rsaKey = _certificate.GetRSAPrivateKey();
            if (rsaKey != null)
            {
                return rsaKey.SignData(message, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            }

            var ecKey = _certificate.GetECDsaPrivateKey();
            if (ecKey != null)
            {
                return ecKey.SignData(message, HashAlgorithmName.SHA256);
            }

            throw new InvalidOperationException("Could not access private key for signing");
        }
    }
}
