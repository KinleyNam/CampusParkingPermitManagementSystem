'use strict';

const { Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const fs = require('fs');
const path = require('path');

const CRYPTO_BASE = path.resolve(__dirname, '../../crypto-config');

const IDENTITIES = [
  {
    label: 'adminUser',
    mspId: 'UniversityAdminMSP',
    orgDomain: 'admin.university.com',
    certPath: path.join(CRYPTO_BASE, 'peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp/signcerts/Admin@admin.university.com-cert.pem'),
    keyDir: path.join(CRYPTO_BASE, 'peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp/keystore'),
  },
  {
    label: 'financeUser',
    mspId: 'FinanceMSP',
    orgDomain: 'finance.university.com',
    certPath: path.join(CRYPTO_BASE, 'peerOrganizations/finance.university.com/users/Admin@finance.university.com/msp/signcerts/Admin@finance.university.com-cert.pem'),
    keyDir: path.join(CRYPTO_BASE, 'peerOrganizations/finance.university.com/users/Admin@finance.university.com/msp/keystore'),
  },
  {
    label: 'securityUser',
    mspId: 'SecurityMSP',
    orgDomain: 'security.university.com',
    certPath: path.join(CRYPTO_BASE, 'peerOrganizations/security.university.com/users/Admin@security.university.com/msp/signcerts/Admin@security.university.com-cert.pem'),
    keyDir: path.join(CRYPTO_BASE, 'peerOrganizations/security.university.com/users/Admin@security.university.com/msp/keystore'),
  },
  {
    label: 'studentAffairsUser',
    mspId: 'StudentAffairsMSP',
    orgDomain: 'studentaffairs.university.com',
    certPath: path.join(CRYPTO_BASE, 'peerOrganizations/studentaffairs.university.com/users/Admin@studentaffairs.university.com/msp/signcerts/Admin@studentaffairs.university.com-cert.pem'),
    keyDir: path.join(CRYPTO_BASE, 'peerOrganizations/studentaffairs.university.com/users/Admin@studentaffairs.university.com/msp/keystore'),
  },
];

async function main() {
  const walletPath = path.join(__dirname, 'wallet');
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  console.log(`Wallet path: ${walletPath}`);

  for (const id of IDENTITIES) {
    const existing = await wallet.get(id.label);
    if (existing) {
      console.log(`Identity "${id.label}" already exists in wallet — skipping.`);
      continue;
    }

    const cert = fs.readFileSync(id.certPath).toString();
    const keyFiles = fs.readdirSync(id.keyDir);
    if (keyFiles.length === 0) {
      console.error(`No private key found in ${id.keyDir}`);
      process.exit(1);
    }
    const key = fs.readFileSync(path.join(id.keyDir, keyFiles[0])).toString();

    const identity = {
      credentials: { certificate: cert, privateKey: key },
      mspId: id.mspId,
      type: 'X.509',
    };

    await wallet.put(id.label, identity);
    console.log(`Stored identity "${id.label}" (${id.mspId}) in wallet.`);
  }

  console.log('Wallet setup complete.');
}

main().catch(err => {
  console.error(`Failed to set up wallet: ${err}`);
  process.exit(1);
});
