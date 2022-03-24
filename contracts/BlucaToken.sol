// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract BlucaToken is ERC20, Ownable {
      using SafeMath for uint256;
   
    /**
     * All of the minted 'Bluc' will be moved to the mainPool.
     */
    address public mainPool;

  

    constructor() 
        public ERC20("Bluca Token", "BLUC") 
    {
       
    }

    /** 
     * Set the target mining pool contract for minting
     */
    function setMainPool(address pool_) external onlyOwner {
        require(pool_ != address(0));
        mainPool = pool_;
    }

    
    function mint(address dest_) external {
        require(msg.sender == mainPool, "invalid minter");

        _mint(dest_, 1000000000 * 10 ** 18); 
    }

    function burn(uint256 amount_) external { 
        _burn(msg.sender, amount_);
    }
}
