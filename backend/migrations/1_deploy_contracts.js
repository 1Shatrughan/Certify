const CertificateManagement = artifacts.require("CertificateManagement");

module.exports = function (deployer) {
  deployer.deploy(CertificateManagement);
};