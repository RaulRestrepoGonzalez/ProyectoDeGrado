const mongoose = require('mongoose');

const passwordRecoverySchema = new mongoose.Schema(
  {
    telefono: { type: String, required: true, unique: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
    codeHash: { type: String, required: true },
    attempts: { type: Number, default: 0 },
    expiresAt: { type: Date, required: true, expires: 0 },
  },
  { timestamps: true },
);

module.exports = mongoose.model('PasswordRecovery', passwordRecoverySchema);