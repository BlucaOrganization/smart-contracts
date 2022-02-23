// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FinalStandardSale {
    using Strings for uint256;
    using SafeMath for uint256;

    constructor(address _ownershipContractAddress, address _busdContractAddress)
    {
        blucamonOwnershipContract = _ownershipContractAddress;
        setter = msg.sender;
        busdContract = _busdContractAddress;
    }

    event PurchaseFinalStandardEgg(uint256 blucamonId, uint8 eventIndex);
    event SetSetter(address _newSetter);
    event SetFounder(address _newFounder);
    event SetEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint8 _rarity,
        uint8 _eventIndex
    );
    event SetPrefixTokenUri(string _newPrefixTokenUri);
    event DisableEvent(uint8 _eventIndex);

    struct SaleEvent {
        uint256 price;
        uint256 total;
        uint256 startTime;
        uint256 endTime;
        uint256 currentNumber;
        uint8 rarity;
    }

    address blucamonOwnershipContract;
    address setter;
    address payable founder;
    string prefixTokenUri;
    address public busdContract;

    SaleEvent[] public events;

    modifier onlySetter() {
        require(msg.sender == setter, "S_FSD_100");
        _;
    }

    function setSetter(address _newSetter) external onlySetter {
        setter = _newSetter;
        emit SetSetter(_newSetter);
    }

    function setFounder(address payable _newFounder) external onlySetter {
        founder = _newFounder;
        emit SetFounder(_newFounder);
    }

    function addSaleEvent() internal onlySetter {
        events.push(
            SaleEvent({
                price: 0,
                total: 0,
                startTime: 0,
                endTime: 0,
                currentNumber: 0,
                rarity: 0
            })
        );
    }

    function initSaleEvents() external onlySetter {
        require(events.length == 0, "S_FSD_700");
        addSaleEvent();
        addSaleEvent();
        addSaleEvent();
    }

    function setEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint8 _rarity,
        uint8 _eventIndex
    ) external onlySetter {
        SaleEvent storage saleEvent = getEventForUpdate(_eventIndex);
        require(
            block.timestamp < saleEvent.startTime ||
                block.timestamp >= saleEvent.endTime,
            "S_FSD_302"
        );
        require(
            block.timestamp <= _startTime && _startTime < _endTime,
            "S_FSD_303"
        );
        saleEvent.currentNumber = 0;
        saleEvent.price = _price;
        saleEvent.total = _total;
        saleEvent.startTime = _startTime;
        saleEvent.endTime = _endTime;
        saleEvent.rarity = _rarity;
        emit SetEvent(
            _price,
            _total,
            _startTime,
            _endTime,
            _rarity,
            _eventIndex
        );
    }

    function getEventForUpdate(uint8 _eventIndex)
        internal
        view
        returns (SaleEvent storage)
    {
        require(_eventIndex >= 0 && _eventIndex < events.length, "S_FSD_600");
        return events[_eventIndex];
    }

    function getEvent(uint8 _eventIndex)
        internal
        view
        returns (SaleEvent memory)
    {
        require(_eventIndex >= 0 && _eventIndex < events.length, "S_FSD_600");
        return events[_eventIndex];
    }

    function setPrefixTokenUri(string memory _newPrefixTokenUri)
        external
        onlySetter
    {
        prefixTokenUri = _newPrefixTokenUri;
        emit SetPrefixTokenUri(_newPrefixTokenUri);
    }

    function disableEvent(uint8 _eventIndex) external onlySetter {
        SaleEvent storage saleEvent = getEventForUpdate(_eventIndex);
        saleEvent.endTime = 0;
        emit DisableEvent(_eventIndex);
    }

    function purchaseEgg(uint8 _eventIndex) external {
        SaleEvent storage saleEvent = getEventForUpdate(_eventIndex);
        validatePurchasing(saleEvent);
        (bool transferResult, ) = busdContract.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                founder,
                saleEvent.price
            )
        );
        require(transferResult, "S_FSD_400");
        saleEvent.currentNumber = saleEvent.currentNumber.add(1);

        uint256 newBlucamonId = getBlucamonId().add(1);
        string memory tokenUri = getTokenUri(newBlucamonId);
        (bool mintResult, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature(
                "mintBlucamon(address,string,bool,uint8,uint256,uint8)",
                msg.sender,
                tokenUri,
                false,
                saleEvent.rarity,
                0,
                0
            )
        );
        require(mintResult, "S_FSD_500");
        emit PurchaseFinalStandardEgg(newBlucamonId, _eventIndex);
    }

    function getBlucamonId() private returns (uint256) {
        (bool result, bytes memory idData) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("getBlucamonId()")
        );
        require(result, "S_FSD_700");
        return abi.decode(idData, (uint256));
    }

    function getTokenUri(uint256 _id) private view returns (string memory) {
        return string(abi.encodePacked(prefixTokenUri, _id.toString()));
    }

    function validatePurchasing(SaleEvent memory _saleEvent) private view {
        require(_saleEvent.currentNumber < _saleEvent.total, "S_FSD_200");
        require(block.timestamp >= _saleEvent.startTime, "S_FSD_300");
        require(block.timestamp < _saleEvent.endTime, "S_FSD_301");
    }

    function getCurrentNumber(uint8 _saleEventIndex)
        external
        view
        returns (uint256)
    {
        SaleEvent memory saleEvent = getEvent(_saleEventIndex);
        return saleEvent.currentNumber;
    }

    function getTotal(uint8 _saleEventIndex) external view returns (uint256) {
        SaleEvent memory saleEvent = getEvent(_saleEventIndex);
        return saleEvent.total;
    }

    function getPrice(uint8 _saleEventIndex) external view returns (uint256) {
        SaleEvent memory saleEvent = getEvent(_saleEventIndex);
        return saleEvent.price;
    }
}
