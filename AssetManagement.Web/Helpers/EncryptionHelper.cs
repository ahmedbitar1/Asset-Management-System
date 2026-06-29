using System.Security.Cryptography;
using System.Text;

namespace AssetManagement.Web.Helpers
{
    public static class EncryptionHelper
    {
        public static string EncryptTripleDES(string input, string key)
        {
            using var tripleDes = new TripleDESCryptoServiceProvider();
            using var sha1      = new SHA1CryptoServiceProvider();

            byte[] keyBytes = Encoding.Unicode.GetBytes(key);
            byte[] hash     = sha1.ComputeHash(keyBytes);
            Array.Resize(ref hash, tripleDes.KeySize / 8);
            tripleDes.Key = hash;

            byte[] ivHash = sha1.ComputeHash(Encoding.Unicode.GetBytes(string.Empty));
            Array.Resize(ref ivHash, tripleDes.BlockSize / 8);
            tripleDes.IV = ivHash;

            tripleDes.Mode    = CipherMode.CBC;
            tripleDes.Padding = PaddingMode.PKCS7;

            using var ms = new MemoryStream();
            using var cs = new CryptoStream(ms, tripleDes.CreateEncryptor(), CryptoStreamMode.Write);
            byte[] inputBytes = Encoding.Unicode.GetBytes(input);
            cs.Write(inputBytes, 0, inputBytes.Length);
            cs.FlushFinalBlock();
            return Convert.ToBase64String(ms.ToArray());
        }
    }
}