// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

contract CertificateManagement {
    address public owner;
    
    // Structure for Institution
    struct Institution {
        string name;
        string email;
        string accreditationId;
        string country;
        bool isRegistered;
        uint256 registrationDate;
    }
    
    // Structure for Certificate
    struct Certificate {
        string studentName;
        string studentId;
        string courseProgram;
        string grade;
        uint256 issueDate;
        string certificateHash; // IPFS hash or similar for certificate file
        address institutionAddress;
        address studentAddress;
        bool isIssued;
    }
    
    // Mappings
    mapping(address => Institution) public institutions;
    mapping(address => Certificate[]) public studentCertificates;
    mapping(address => bool) public registeredInstitutions;
    mapping(string => bool) public usedCertificateHashes;
    
    // Events
    event InstitutionRegistered(
        address indexed institutionAddress,
        string name,
        string email,
        string accreditationId,
        string country,
        uint256 timestamp
    );
    
    event CertificateIssued(
        address indexed studentAddress,
        address indexed institutionAddress,
        string studentName,
        string courseProgram,
        string certificateHash,
        uint256 timestamp
    );
    
    event CertificateVerified(
        address indexed studentAddress,
        address indexed institutionAddress,
        bool isValid,
        uint256 timestamp
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyRegisteredInstitution() {
        require(registeredInstitutions[msg.sender], "Only registered institutions can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Register a new institution
     */
    function registerInstitution(
        address _institutionAddress,
        string memory _name,
        string memory _email,
        string memory _accreditationId,
        string memory _country
    ) external onlyOwner {
        require(_institutionAddress != address(0), "Invalid institution address");
        require(!registeredInstitutions[_institutionAddress], "Institution already registered");
        require(bytes(_name).length > 0, "Institution name cannot be empty");
        require(bytes(_accreditationId).length > 0, "Accreditation ID cannot be empty");
        
        institutions[_institutionAddress] = Institution({
            name: _name,
            email: _email,
            accreditationId: _accreditationId,
            country: _country,
            isRegistered: true,
            registrationDate: block.timestamp
        });
        
        registeredInstitutions[_institutionAddress] = true;
        
        emit InstitutionRegistered(
            _institutionAddress,
            _name,
            _email,
            _accreditationId,
            _country,
            block.timestamp
        );
    }
    
    /**
     * @dev Issue a certificate to a student
     */
    function issueCertificate(
        string memory _studentName,
        string memory _studentId,
        string memory _courseProgram,
        string memory _grade,
        string memory _certificateHash,
        address _studentAddress
    ) external onlyRegisteredInstitution {
        require(_studentAddress != address(0), "Invalid student address");
        require(bytes(_studentName).length > 0, "Student name cannot be empty");
        require(bytes(_courseProgram).length > 0, "Course program cannot be empty");
        require(bytes(_certificateHash).length > 0, "Certificate hash cannot be empty");
        require(!usedCertificateHashes[_certificateHash], "Certificate hash already used");
        
        Certificate memory newCertificate = Certificate({
            studentName: _studentName,
            studentId: _studentId,
            courseProgram: _courseProgram,
            grade: _grade,
            issueDate: block.timestamp,
            certificateHash: _certificateHash,
            institutionAddress: msg.sender,
            studentAddress: _studentAddress,
            isIssued: true
        });
        
        studentCertificates[_studentAddress].push(newCertificate);
        usedCertificateHashes[_certificateHash] = true;
        
        emit CertificateIssued(
            _studentAddress,
            msg.sender,
            _studentName,
            _courseProgram,
            _certificateHash,
            block.timestamp
        );
    }
    
    /**
     * @dev Verify if a certificate exists for a student
     */
    function verifyCertificate(address _studentAddress) external view returns (
        bool hasCertificates,
        uint256 certificateCount,
        address[] memory institutionAddresses,
        string[] memory courses,
        uint256[] memory issueDates
    ) {
        Certificate[] memory certificates = studentCertificates[_studentAddress];
        certificateCount = certificates.length;
        hasCertificates = certificateCount > 0;
        
        institutionAddresses = new address[](certificateCount);
        courses = new string[](certificateCount);
        issueDates = new uint256[](certificateCount);
        
        for (uint256 i = 0; i < certificateCount; i++) {
            institutionAddresses[i] = certificates[i].institutionAddress;
            courses[i] = certificates[i].courseProgram;
            issueDates[i] = certificates[i].issueDate;
        }
        
        return (hasCertificates, certificateCount, institutionAddresses, courses, issueDates);
    }
    
    /**
     * @dev Get detailed certificate information for a student
     */
    function getStudentCertificates(address _studentAddress) external view returns (Certificate[] memory) {
        return studentCertificates[_studentAddress];
    }
    
    /**
     * @dev Get specific certificate details by index
     */
    function getCertificateDetails(address _studentAddress, uint256 _index) external view returns (
        string memory studentName,
        string memory studentId,
        string memory courseProgram,
        string memory grade,
        uint256 issueDate,
        string memory certificateHash,
        address institutionAddress,
        bool isIssued
    ) {
        require(_index < studentCertificates[_studentAddress].length, "Invalid certificate index");
        
        Certificate memory cert = studentCertificates[_studentAddress][_index];
        
        return (
            cert.studentName,
            cert.studentId,
            cert.courseProgram,
            cert.grade,
            cert.issueDate,
            cert.certificateHash,
            cert.institutionAddress,
            cert.isIssued
        );
    }
    
    /**
     * @dev Check if an institution is registered
     */
    function isInstitutionRegistered(address _institutionAddress) external view returns (bool) {
        return registeredInstitutions[_institutionAddress];
    }
    
    /**
     * @dev Get institution details
     */
    function getInstitutionDetails(address _institutionAddress) external view returns (
        string memory name,
        string memory email,
        string memory accreditationId,
        string memory country,
        bool isRegistered,
        uint256 registrationDate
    ) {
        Institution memory institution = institutions[_institutionAddress];
        return (
            institution.name,
            institution.email,
            institution.accreditationId,
            institution.country,
            institution.isRegistered,
            institution.registrationDate
        );
    }
    
    /**
     * @dev Get total certificates issued to a student
     */
    function getCertificateCount(address _studentAddress) external view returns (uint256) {
        return studentCertificates[_studentAddress].length;
    }
    
    /**
     * @dev Remove an institution (only owner)
     */
    function removeInstitution(address _institutionAddress) external onlyOwner {
        require(registeredInstitutions[_institutionAddress], "Institution not registered");
        
        delete institutions[_institutionAddress];
        registeredInstitutions[_institutionAddress] = false;
    }
    
    /**
     * @dev Transfer ownership (only owner)
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
    }
}