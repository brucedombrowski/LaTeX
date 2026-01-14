using System;
using System.IO;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using iText.Kernel.Pdf;
using iText.Signatures;
using Org.BouncyCastle.X509;

namespace PdfSigner
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
                Console.WriteLine($"Selected certificate: {cert.Subject}");
                Console.WriteLine($"Issuer: {cert.Issuer}");
                Console.WriteLine($"Valid: {cert.NotBefore:yyyy-MM-dd} to {cert.NotAfter:yyyy-MM-dd}");
                Console.WriteLine();

                // Sign the PDF
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

        static void ListCertificates()
        {
            Console.WriteLine("Available signing certificates in Windows Certificate Store:");
            Console.WriteLine();

            using var store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            store.Open(OpenFlags.ReadOnly);

            int index = 0;
            foreach (var cert in store.Certificates)
            {
                // Check if cert can be used for digital signatures
                bool canSign = false;
                foreach (var ext in cert.Extensions)
                {
                    if (ext is X509KeyUsageExtension keyUsage)
                    {
                        canSign = (keyUsage.KeyUsages & X509KeyUsageFlags.DigitalSignature) != 0;
                        break;
                    }
                }

                // Also check if it has a private key
                if (cert.HasPrivateKey)
                {
                    index++;
                    string smartCard = IsSmartCardCert(cert) ? " [SMART CARD]" : "";
                    Console.WriteLine($"[{index}] {cert.Subject}{smartCard}");
                    Console.WriteLine($"    Issuer: {cert.Issuer}");
                    Console.WriteLine($"    Expires: {cert.NotAfter:yyyy-MM-dd}");
                    Console.WriteLine($"    Thumbprint: {cert.Thumbprint}");
                    Console.WriteLine($"    Can Sign: {canSign}");
                    Console.WriteLine();
                }
            }

            if (index == 0)
            {
                Console.WriteLine("No signing certificates found.");
                Console.WriteLine();
                Console.WriteLine("If you have a PIV/CAC smart card inserted, ensure:");
                Console.WriteLine("  1. The card reader drivers are installed");
                Console.WriteLine("  2. The smart card middleware is configured");
                Console.WriteLine("  3. The certificate appears in certmgr.msc");
            }
        }

        static bool IsSmartCardCert(X509Certificate2 cert)
        {
            // Smart card certs typically have CSP info indicating hardware
            try
            {
                if (cert.HasPrivateKey)
                {
                    using var key = cert.GetRSAPrivateKey();
                    if (key is RSACng rsaCng)
                    {
                        var keyHandle = rsaCng.Key;
                        // Hardware-based keys will have different properties
                        return keyHandle.IsEphemeral == false;
                    }
                }
            }
            catch
            {
                // If we can't access the key without PIN, it's likely a smart card
                return true;
            }
            return false;
        }

        static X509Certificate2? SelectSigningCertificate()
        {
            using var store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            store.Open(OpenFlags.ReadOnly);

            // Filter to certificates with private keys that can sign
            var signingCerts = new X509Certificate2Collection();
            foreach (var cert in store.Certificates)
            {
                if (cert.HasPrivateKey)
                {
                    signingCerts.Add(cert);
                }
            }

            if (signingCerts.Count == 0)
            {
                Console.WriteLine("No certificates with private keys found.");
                return null;
            }

            // Show Windows certificate selection dialog
            // This will show smart card certificates and prompt for PIN when needed
            var selected = X509Certificate2UI.SelectFromCollection(
                signingCerts,
                "Select Signing Certificate",
                "Choose a certificate to sign the PDF document:",
                X509SelectionFlag.SingleSelection);

            return selected.Count > 0 ? selected[0] : null;
        }

        static void SignPdf(string inputPath, string outputPath, X509Certificate2 cert)
        {
            Console.WriteLine("Signing PDF...");
            Console.WriteLine("(Windows Security may prompt for your PIN)");

            // Convert .NET cert to BouncyCastle cert for iText
            var bcCert = new X509CertificateParser().ReadCertificate(cert.RawData);
            var chain = new Org.BouncyCastle.X509.X509Certificate[] { bcCert };

            // Create external signature using Windows CNG (triggers PIN dialog)
            var externalSignature = new X509Certificate2Signature(cert, "SHA256");

            using var reader = new PdfReader(inputPath);
            using var outputStream = new FileStream(outputPath, FileMode.Create, FileAccess.Write);

            var signer = new PdfSigner(reader, outputStream, new StampingProperties());

            // Set signature appearance
            var appearance = signer.GetSignatureAppearance();
            appearance
                .SetReason("Document Approval")
                .SetLocation("Digital Signature")
                .SetContact(cert.Subject);

            // Perform the signature - this triggers the PIN dialog for smart cards
            signer.SignDetached(externalSignature, chain, null, null, null, 0, PdfSigner.CryptoStandard.CMS);
        }
    }

    /// <summary>
    /// External signature implementation using Windows Certificate Store
    /// This class bridges iText's signature interface with .NET's X509Certificate2
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
            // This is where the magic happens - Windows CNG will prompt for PIN
            // when accessing a smart card private key

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
