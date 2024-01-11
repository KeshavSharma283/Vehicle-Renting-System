// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract VehicleRentingSystem {
    address public owner;

    enum VehicleStatus { Available, Rented }

    struct Vehicle {
        string make;
        string model;
        uint256 rentalPrice;
        VehicleStatus status;
    }

    struct Renter {
        address renterAddress;
        string name;
    }

    struct Rentee {
        address renteeAddress;
        string name;
        uint256 balance;
    }

    address payable[] public vehiclesAddresses;

    mapping(address => Vehicle) public vehicles;
    mapping(address => Renter) public renters;
    mapping(address => Rentee) public rentees;

    event VehicleAdded(address indexed vehicleAddress, string make, string model, uint256 rentalPrice);
    event VehicleRented(address indexed vehicleAddress, address indexed renteeAddress, uint256 rentalAmount);
    event MoneyTransferred(address indexed renterAddress, address indexed renteeAddress, uint256 amount);
    event RenterRegistered(address indexed renterAddress, string name);
    event VehicleReturned(address indexed vehicleAddress, address indexed renteeAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyRenter() {
        require(renters[msg.sender].renterAddress == msg.sender, "Not a registered renter");
        _;
    }

    modifier vehicleExists(address vehicleAddress) {
        require(vehicles[vehicleAddress].status == VehicleStatus.Available, "Vehicle is not available");
        _;
    }

    modifier renterExists(address renterAddress) {
        require(renters[renterAddress].renterAddress == renterAddress, "Renter not registered");
        _;
    }

    modifier renteeExists(address renteeAddress) {
        require(rentees[renteeAddress].renteeAddress == renteeAddress, "Rentee not registered");
        _;
    }

    modifier rentedVehicleExists(address vehicleAddress) {
        require(vehicles[vehicleAddress].status == VehicleStatus.Rented, "Vehicle is not rented");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function addVehicle(string calldata make, string calldata model, uint256 rentalPrice) external onlyRenter {
        address payable vehicleAddress = address(uint160(msg.sender)); // Use the renter's address as the vehicle address

        vehicles[vehicleAddress] = Vehicle({
            make: make,
            model: model,
            rentalPrice: rentalPrice,
            status: VehicleStatus.Available
        });

        vehiclesAddresses.push(vehicleAddress);

        emit VehicleAdded(vehicleAddress, make, model, rentalPrice);
    }

    function registerRenter(address renterAddress, string calldata name) external onlyOwner {
        renters[renterAddress] = Renter({
            renterAddress: renterAddress,
            name: name
        });
        emit RenterRegistered(renterAddress, name);
    }

    function registerRentee(address renteeAddress, string calldata name, uint256 initialBalance) external onlyOwner {
        rentees[renteeAddress] = Rentee({
            renteeAddress: renteeAddress,
            name: name,
            balance: initialBalance
        });
    }

    function displayAvailableVehicles() external view returns (address payable[] memory) {
        address payable[] memory availableVehicles = new address payable[](getAvailableVehicleCount());
        uint256 index = 0;

        for (uint256 i = 0; i < vehiclesAddresses.length; i++) {
            address payable vehicleAddress = vehiclesAddresses[i];
            if (vehicles[vehicleAddress].status == VehicleStatus.Available) {
                availableVehicles[index] = vehicleAddress;
                index++;
            }
        }

        return availableVehicles;
    }

    function rentVehicle(address payable vehicleAddress) external payable
        vehicleExists(vehicleAddress)
        renteeExists(msg.sender)
    {
        address renteeAddress = msg.sender;
        require(msg.value >= vehicles[vehicleAddress].rentalPrice, "Incorrect rental amount");

        vehicles[vehicleAddress].status = VehicleStatus.Rented;
        uint256 rentalAmount = vehicles[vehicleAddress].rentalPrice;
        rentees[renteeAddress].balance -= rentalAmount;
        
        address payable renterAddressPayable = address(uint160(renters[msg.sender].renterAddress));
        renterAddressPayable.transfer(rentalAmount);

        emit VehicleRented(vehicleAddress, renteeAddress, rentalAmount);
        emit MoneyTransferred(msg.sender, renteeAddress, rentalAmount);
    }

    function returnVehicle(address payable vehicleAddress) external
        rentedVehicleExists(vehicleAddress)
        renteeExists(msg.sender)
    {
        address renteeAddress = msg.sender;

        // Mark the vehicle as available
        vehicles[vehicleAddress].status = VehicleStatus.Available;

        // Emit an event to log the return of the vehicle
        emit VehicleReturned(vehicleAddress, renteeAddress);
    }

    function getVehicleDetails(address vehicleAddress) external view returns (string memory, string memory, uint256, VehicleStatus) {
        return (
            vehicles[vehicleAddress].make,
            vehicles[vehicleAddress].model,
            vehicles[vehicleAddress].rentalPrice,
            vehicles[vehicleAddress].status
        );
    }

    function getAvailableVehicleCount() public view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < vehiclesAddresses.length; i++) {
            address payable vehicleAddress = vehiclesAddresses[i];
            if (vehicles[vehicleAddress].status == VehicleStatus.Available) {
                count++;
            }
        }

        return count;
    }
}
