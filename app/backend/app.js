'use strict';

const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const WALLET_PATH = path.resolve(__dirname, process.env.WALLET_PATH || '../wallet-project/wallet');
const CONN_PARKING = path.resolve(__dirname, process.env.CONNECTION_PARKING || '../wallet-project/connection-parking.json');
const CONN_FINANCE = path.resolve(__dirname, process.env.CONNECTION_FINANCE || '../wallet-project/connection-finance.json');

const PARKING_CHANNEL = process.env.PARKING_CHANNEL || 'parking-main-channel';
const FINANCE_CHANNEL = process.env.FINANCE_CHANNEL || 'finance-channel';
const PARKING_CC = process.env.PARKING_CHAINCODE || 'parkingmgt';
const FINANCE_CC = process.env.FINANCE_CHAINCODE || 'financemgt';

async function getContract(identityLabel, connectionProfilePath, channelName, chaincodeName) {
  const wallet = await Wallets.newFileSystemWallet(WALLET_PATH);
  const identity = await wallet.get(identityLabel);
  if (!identity) throw new Error(`Identity "${identityLabel}" not found in wallet. Run wallet.js first.`);

  const connectionProfile = JSON.parse(fs.readFileSync(connectionProfilePath, 'utf8'));
  const gateway = new Gateway();
  await gateway.connect(connectionProfile, {
    wallet,
    identity: identityLabel,
    discovery: { enabled: false, asLocalhost: true },
  });

  const network = await gateway.getNetwork(channelName);
  const contract = network.getContract(chaincodeName);
  return { gateway, contract };
}

// ─── Parking channel helpers ──────────────────────────────────────────────────

async function parkingSubmit(identityLabel, fn, ...args) {
  const { gateway, contract } = await getContract(
    identityLabel, CONN_PARKING, PARKING_CHANNEL, PARKING_CC
  );
  try {
    const result = await contract.submitTransaction(fn, ...args);
    return result.toString();
  } finally {
    gateway.disconnect();
  }
}

async function parkingEvaluate(identityLabel, fn, ...args) {
  const { gateway, contract } = await getContract(
    identityLabel, CONN_PARKING, PARKING_CHANNEL, PARKING_CC
  );
  try {
    const result = await contract.evaluateTransaction(fn, ...args);
    return JSON.parse(result.toString());
  } finally {
    gateway.disconnect();
  }
}

// ─── Finance channel helpers ──────────────────────────────────────────────────

async function financeSubmit(identityLabel, fn, ...args) {
  const { gateway, contract } = await getContract(
    identityLabel, CONN_FINANCE, FINANCE_CHANNEL, FINANCE_CC
  );
  try {
    const result = await contract.submitTransaction(fn, ...args);
    return result.toString();
  } finally {
    gateway.disconnect();
  }
}

async function financeEvaluate(identityLabel, fn, ...args) {
  const { gateway, contract } = await getContract(
    identityLabel, CONN_FINANCE, FINANCE_CHANNEL, FINANCE_CC
  );
  try {
    const result = await contract.evaluateTransaction(fn, ...args);
    return JSON.parse(result.toString());
  } finally {
    gateway.disconnect();
  }
}

// ─── Exported API functions ───────────────────────────────────────────────────

// Permits
exports.issuePermit = (permitId, studentId, vehicleNumber, permitType, issueDate, expiryDate, parkingZone) =>
  parkingSubmit(process.env.ADMIN_USER || 'adminUser', 'IssuePermit',
    permitId, studentId, vehicleNumber, permitType, issueDate, expiryDate, parkingZone);

exports.readPermit = (permitId) =>
  parkingEvaluate(process.env.ADMIN_USER || 'adminUser', 'ReadPermit', permitId);

exports.updatePermitStatus = (permitId, newStatus) =>
  parkingSubmit(process.env.ADMIN_USER || 'adminUser', 'UpdatePermitStatus', permitId, newStatus);

exports.revokePermit = (permitId) =>
  parkingSubmit(process.env.ADMIN_USER || 'adminUser', 'RevokePermit', permitId);

exports.verifyPermit = (permitId) =>
  parkingEvaluate(process.env.SECURITY_USER || 'securityUser', 'VerifyPermit', permitId);

// Violations
exports.recordViolation = (violationId, permitId, studentId, vehicleNumber, description, timestamp, fine) =>
  parkingSubmit(process.env.SECURITY_USER || 'securityUser', 'RecordViolation',
    violationId, permitId, studentId, vehicleNumber, description, timestamp, fine);

exports.readViolation = (violationId) =>
  parkingEvaluate(process.env.SECURITY_USER || 'securityUser', 'ReadViolation', violationId);

exports.deleteViolation = (violationId) =>
  parkingSubmit(process.env.SECURITY_USER || 'securityUser', 'DeleteViolation', violationId);

// Student Eligibility
exports.setStudentEligibility = (studentId, name, isEligible, program, updatedAt) =>
  parkingSubmit(process.env.STUDENT_AFFAIRS_USER || 'studentAffairsUser', 'SetStudentEligibility',
    studentId, name, String(isEligible), program, updatedAt);

exports.getStudentEligibility = (studentId) =>
  parkingEvaluate(process.env.STUDENT_AFFAIRS_USER || 'studentAffairsUser', 'GetStudentEligibility', studentId);

// Payments
exports.recordPayment = (paymentId, studentId, permitId, amount, paymentDate) =>
  financeSubmit(process.env.ADMIN_USER || 'adminUser', 'RecordPayment',
    paymentId, studentId, permitId, amount, paymentDate);

exports.readPayment = (paymentId) =>
  financeEvaluate(process.env.ADMIN_USER || 'adminUser', 'ReadPayment', paymentId);

exports.confirmPayment = (paymentId) =>
  financeSubmit(process.env.FINANCE_USER || 'financeUser', 'ConfirmPayment', paymentId);

exports.updatePayment = (paymentId, amount, paymentDate) =>
  financeSubmit(process.env.ADMIN_USER || 'adminUser', 'UpdatePayment', paymentId, amount, paymentDate);

exports.deletePayment = (paymentId) =>
  financeSubmit(process.env.ADMIN_USER || 'adminUser', 'DeletePayment', paymentId);
