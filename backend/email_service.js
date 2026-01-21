// backend/email_service.js
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.ethereal.email', // Use Ethereal for testing
  port: 587,
  secure: false, // Use TLS
  auth: {
    user: 'your_ethereal_email_user', // Replace with your Ethereal user
    pass: 'your_ethereal_email_pass'  // Replace with your Ethereal password
  }
});

async function sendLowStockEmail(toEmail, farmName, productName, currentStock, threshold) {
  const mailOptions = {
    from: '"Lung Chaing Farm" <no-reply@lungchaingfarm.com>', // Sender address
    to: toEmail, // List of receivers
    subject: `Low Stock Alert: ${productName} from ${farmName}`, // Subject line
    html: `
      <p>Dear ${farmName} farmer,</p>
      <p>This is an automated alert from Lung Chaing Farm marketplace.</p>
      <p>Your product <strong>${productName}</strong> has reached a low stock level.</p>
      <p>Current Stock: <strong>${currentStock} kg</strong></p>
      <p>Low Stock Threshold: <strong>${threshold} kg</strong></p>
      <p>Please consider restocking your product to continue selling on our platform.</p>
      <p>Thank you,</p>
      <p>The Lung Chaing Farm Team</p>
    `, // HTML body
  };

  try {
    let info = await transporter.sendMail(mailOptions);
    console.log('Email sent: %s', info.messageId);
    console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));
    return true;
  } catch (error) {
    console.error('Error sending low stock email:', error);
    return false;
  }
}

module.exports = {
  sendLowStockEmail
};
