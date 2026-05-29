'use strict';

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const fabric = require('./app');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const respond = (res, promise) =>
  promise
    .then(data => res.json({ success: true, data: data || null }))
    .catch(err => res.status(500).json({ success: false, error: err.message }));

// ─── Permit routes ────────────────────────────────────────────────────────────
app.post('/api/permits', (req, res) => {
  const { permitId, studentId, vehicleNumber, permitType, issueDate, expiryDate, parkingZone } = req.body;
  respond(res, fabric.issuePermit(permitId, studentId, vehicleNumber, permitType, issueDate, expiryDate, parkingZone));
});

app.get('/api/permits/:permitId', (req, res) => {
  respond(res, fabric.readPermit(req.params.permitId));
});

app.put('/api/permits/:permitId/status', (req, res) => {
  respond(res, fabric.updatePermitStatus(req.params.permitId, req.body.status));
});

app.delete('/api/permits/:permitId', (req, res) => {
  respond(res, fabric.revokePermit(req.params.permitId));
});

app.get('/api/permits/:permitId/verify', (req, res) => {
  respond(res, fabric.verifyPermit(req.params.permitId));
});

// ─── Violation routes ─────────────────────────────────────────────────────────
app.post('/api/violations', (req, res) => {
  const { violationId, permitId, studentId, vehicleNumber, description, timestamp, fine } = req.body;
  respond(res, fabric.recordViolation(violationId, permitId, studentId, vehicleNumber, description, timestamp, fine));
});

app.get('/api/violations/:violationId', (req, res) => {
  respond(res, fabric.readViolation(req.params.violationId));
});

app.delete('/api/violations/:violationId', (req, res) => {
  respond(res, fabric.deleteViolation(req.params.violationId));
});

// ─── Student Eligibility routes ───────────────────────────────────────────────
app.post('/api/eligibility', (req, res) => {
  const { studentId, name, isEligible, program, updatedAt } = req.body;
  respond(res, fabric.setStudentEligibility(studentId, name, isEligible, program, updatedAt));
});

app.get('/api/eligibility/:studentId', (req, res) => {
  respond(res, fabric.getStudentEligibility(req.params.studentId));
});

// ─── Payment routes ───────────────────────────────────────────────────────────
app.post('/api/payments', (req, res) => {
  const { paymentId, studentId, permitId, amount, paymentDate } = req.body;
  respond(res, fabric.recordPayment(paymentId, studentId, permitId, amount, paymentDate));
});

app.get('/api/payments/:paymentId', (req, res) => {
  respond(res, fabric.readPayment(req.params.paymentId));
});

app.put('/api/payments/:paymentId/confirm', (req, res) => {
  respond(res, fabric.confirmPayment(req.params.paymentId));
});

app.put('/api/payments/:paymentId', (req, res) => {
  const { amount, paymentDate } = req.body;
  respond(res, fabric.updatePayment(req.params.paymentId, amount, paymentDate));
});

app.delete('/api/payments/:paymentId', (req, res) => {
  respond(res, fabric.deletePayment(req.params.paymentId));
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`CPPMS backend listening on http://localhost:${PORT}`));
