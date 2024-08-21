pragma circom 2.0.0;

include "../../../src/dns/DNSKEY.circom";
include "../../../src/dns/DS.circom";

template RSAfromRSA() {
  // standard constants
  var MAX_SLD_NAME_LEN = 63 + 24 + 3;
  var MAX_TLD_NAME_LEN = 24 + 2;
  var MAX_RSA_SIG_LEN = 256;
  var MAX_RSA_KEY_LEN = MAX_RSA_SIG_LEN + 4;
  // 18 + 26 + 2 * (26 + 10 + 4 + 260)
  var MAX_TLD_DNSKEY_REC_LEN = 644;

  // names
  signal input child_name[MAX_TLD_NAME_LEN];
  signal input child_name_len;
  // parent ZSK
  signal input parent_zsk[MAX_RSA_KEY_LEN];
  signal input parent_zsk_len;
  // DS record suffix for the TLD
  signal input ds_rec_suffix[128];
  signal input ds_hash_offset;
  signal input ds_prev_hash_bits[8][32];
  signal input ds_sig[MAX_RSA_SIG_LEN];
  signal input ds_sig_len;
  // DNSKEY record for the TLD
  signal input dnskey_rec[MAX_TLD_DNSKEY_REC_LEN];
  signal input dnskey_rec_len;
  signal input dnskey_sig[MAX_RSA_SIG_LEN];
  signal input dnskey_sig_len;
  signal input ksk[MAX_TLD_NAME_LEN + 4 + MAX_RSA_KEY_LEN];
  signal input ksk_len;
  // child ZSK
  signal input child_zsk[MAX_RSA_KEY_LEN];
  signal input child_zsk_len;

  // DNSKEY parse and sig
  component KSKExtract = ExtractKSK(MAX_TLD_NAME_LEN, MAX_RSA_KEY_LEN, 8);
  KSKExtract.ksk <== ksk;
  KSKExtract.real_ksk_byte_len <== ksk_len;
  KSKExtract.real_name_byte_len <== child_name_len;
  component DNSKEYVerify = VerifyDNSKEYRSA(MAX_TLD_DNSKEY_REC_LEN, MAX_RSA_SIG_LEN, MAX_RSA_KEY_LEN, MAX_TLD_NAME_LEN);
  DNSKEYVerify.rec <== dnskey_rec;
  DNSKEYVerify.real_rec_byte_len <== dnskey_rec_len;
  DNSKEYVerify.sig <== dnskey_sig;
  DNSKEYVerify.real_sig_byte_len <== dnskey_sig_len;
  DNSKEYVerify.ksk <== KSKExtract.key;
  DNSKEYVerify.real_ksk_byte_len <== KSKExtract.real_key_byte_len;
  DNSKEYVerify.zsk <== child_zsk;
  DNSKEYVerify.real_zsk_byte_len <== child_zsk_len;
  DNSKEYVerify.sname <== child_name;
  DNSKEYVerify.real_name_byte_len <== child_name_len;
  // KSK hash
  component HashKSK = SHA256(MAX_TLD_NAME_LEN + 4 + MAX_RSA_KEY_LEN);
  HashKSK.msg <== ksk;
  HashKSK.real_byte_len <== ksk_len;
  // DS parse and sig
  component DSVerify = VerifyDSSuffixFromHashRSA(MAX_RSA_SIG_LEN, MAX_RSA_KEY_LEN, 8);
  DSVerify.suffix <== ds_rec_suffix;
  DSVerify.offset <== ds_hash_offset;
  DSVerify.prev_hash_bits <== ds_prev_hash_bits;
  DSVerify.sig <== ds_sig;
  DSVerify.key <== parent_zsk;
  DSVerify.ksk_hash <== HashKSK.hash;
  DSVerify.real_sig_byte_len <== ds_sig_len;
  DSVerify.real_key_byte_len <== parent_zsk_len;
}

component main = RSAfromRSA();