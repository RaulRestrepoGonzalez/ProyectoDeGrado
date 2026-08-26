const buildWhatsAppRecoveryUrl = (telefono, code) => {
  const phone = telefono.replace(/\D/g, '');
  const message = encodeURIComponent(
    `Código de recuperación de SoundUpar: ${code}. Cópialo y pégalo en la aplicación.`,
  );
  return `https://wa.me/${phone}?text=${message}`;
};

module.exports = { buildWhatsAppRecoveryUrl };