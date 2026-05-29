'use strict';

const BASE = '/api';

function show(data) {
  document.getElementById('responseBox').textContent =
    typeof data === 'object' ? JSON.stringify(data, null, 2) : String(data);
}

function val(id) {
  return document.getElementById(id).value.trim();
}

async function call(method, path, body) {
  try {
    const opts = { method, headers: { 'Content-Type': 'application/json' } };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(BASE + path, opts);
    const json = await res.json();
    show(json);
  } catch (err) {
    show({ error: err.message });
  }
}

// ── Permits ───────────────────────────────────────────────────────────────────
function issuePermit() {
  call('POST', '/permits', {
    permitId: val('p-permitId'),
    studentId: val('p-studentId'),
    vehicleNumber: val('p-vehicleNum'),
    permitType: val('p-permitType'),
    issueDate: val('p-issueDate'),
    expiryDate: val('p-expiryDate'),
    parkingZone: val('p-zone'),
  });
}

function readPermit() { call('GET', `/permits/${val('rp-permitId')}`); }

function updatePermitStatus() {
  call('PUT', `/permits/${val('up-permitId')}/status`, { status: val('up-status') });
}

function revokePermit() { call('DELETE', `/permits/${val('rv-permitId')}`); }

function verifyPermit() { call('GET', `/permits/${val('vp-permitId')}/verify`); }

// ── Violations ────────────────────────────────────────────────────────────────
function recordViolation() {
  call('POST', '/violations', {
    violationId: val('v-violationId'),
    permitId: val('v-permitId'),
    studentId: val('v-studentId'),
    vehicleNumber: val('v-vehicleNum'),
    description: val('v-desc'),
    timestamp: val('v-timestamp'),
    fine: val('v-fine'),
  });
}

function readViolation() { call('GET', `/violations/${val('rv2-violationId')}`); }

function deleteViolation() { call('DELETE', `/violations/${val('dv-violationId')}`); }

// ── Eligibility ───────────────────────────────────────────────────────────────
function setEligibility() {
  call('POST', '/eligibility', {
    studentId: val('e-studentId'),
    name: val('e-name'),
    isEligible: val('e-eligible') === 'true',
    program: val('e-program'),
    updatedAt: val('e-updatedAt'),
  });
}

function getEligibility() { call('GET', `/eligibility/${val('ge-studentId')}`); }

// ── Payments ──────────────────────────────────────────────────────────────────
function recordPayment() {
  call('POST', '/payments', {
    paymentId: val('pay-paymentId'),
    studentId: val('pay-studentId'),
    permitId: val('pay-permitId'),
    amount: val('pay-amount'),
    paymentDate: val('pay-date'),
  });
}

function readPayment() { call('GET', `/payments/${val('rpay-paymentId')}`); }

function confirmPayment() { call('PUT', `/payments/${val('cp-paymentId')}/confirm`); }

function updatePayment() {
  call('PUT', `/payments/${val('upay-paymentId')}`, {
    amount: val('upay-amount'),
    paymentDate: val('upay-date'),
  });
}

function deletePayment() { call('DELETE', `/payments/${val('dpay-paymentId')}`); }
