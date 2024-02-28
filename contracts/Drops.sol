//SPDX-Liscence-Identifier: MIT

pragma solidity 0.8.20;

import "dependencies/openzeppelin-contracts/contracts/access/Ownable.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "dependencies/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "dependencies/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract Drops is ERC20, Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint public swapAndLiqThreshold = 1e3 ether; //1,000 tokens -> 0.1% TS
    uint public purchaseLimit;
    uint public buySellTax;

    bool private inSwapAndLiquify;
    bool public tradingOpen;

    uint256 public liquidityFee;
    uint256 public ethFee;

    uint256 private tokensForLiquidity;
    uint256 private tokensForETH;

    address public feeWallet;

    // mappings
    mapping (address => bool) private _isExcludedFromLimit;

    event ExcludeFromLimitation(address indexed account, bool isExcluded);
    event BatchExcludeFromLimitation(address[] account, bool[] isExcluded);
    event SwapAndLiquified(uint256 tokensSwapped, uint256 tokensForLiquidity, uint256 ethForLiquidity, uint256 ethForMarketing);
    event TaxUpdated(uint taxPercent);
    event PurchaseLimitUpdated(uint limitPercent);
    event SwapAndLiqThresholdSet(uint256 amount);
    event ETHWithdrawn(address indexed to, uint256 amount);
    event ERC20Withdrawn(address indexed to, uint256 amount);
    event TradingStatusUpdated(bool status);

    modifier lockTheSwap {
        require(!inSwapAndLiquify, "Currently in swap and liquify");
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _router, uint256 _buySellTax,uint256 __ethFeeInPercent,uint256 __liquidityFeeInPercent, uint256 __purchaseLimit, address _feeWallet) ERC20("Drops2", "DROPS2") Ownable(msg.sender) {
        _mint(_msgSender(), 1e6 ether);

        feeWallet = payable(_feeWallet);
        address uniswapRouter = _router; // Uniswap router address for BSC
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory _uniswapFactory = IUniswapV2Factory(_uniswapV2Router.factory());

        ethFee = __ethFeeInPercent;
        liquidityFee = __liquidityFeeInPercent;

        address _uniswapV2Pair = _uniswapFactory.createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        buySellTax = _buySellTax;
        purchaseLimit = __purchaseLimit;

        excludeFromLimitation(uniswapV2Pair, true);
        excludeFromLimitation(address(uniswapRouter), true);
        excludeFromLimitation(_msgSender(), true);
        excludeFromLimitation(address(this), true);
    }

    receive() external payable {}

    function swapAndLiquify(uint256 toSwapLiquidity) private lockTheSwap {

        uint256 initialBalance = address(this).balance;

        uint256 totalFee = buySellTax / 100;

        uint256 forETH = toSwapLiquidity * ethFee / totalFee;
        uint256 forLiquidity = toSwapLiquidity * liquidityFee / totalFee;
        
        uint256 tokensToSellForLiq = forLiquidity / 2;
        uint256 tokensToAddLiq = forLiquidity - tokensToSellForLiq;

        uint256 toSwap = forETH+tokensToSellForLiq;

        swapTokensForETH(toSwap);
        
        uint256 updatedBalance = address(this).balance - initialBalance;

        uint256 ethForMarketing = updatedBalance * forETH / toSwapLiquidity;
        uint256 ethForLiquidity = updatedBalance - ethForMarketing;

        addLiquidity(tokensToAddLiq, ethForLiquidity);

        payable(feeWallet).transfer(ethForMarketing);

        emit SwapAndLiquified(toSwap, tokensToAddLiq, ethForLiquidity, ethForMarketing);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Custom transfer function with buy and sell fees and burn functionality
    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than 0");
        if(!_isExcludedFromLimit[from] || !_isExcludedFromLimit[to]) {
            require(tradingOpen, "Trading Closed");
        }

        uint256 taxAmount = 0;

        // Max Purchase Limitation
        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromLimit[to]) {

            require(amount <= totalSupply() * purchaseLimit / 1e4, "Amount exceeds max purchase amount.");
        }

        if((!_isExcludedFromLimit[from] || !_isExcludedFromLimit[to]) && from != address(this)){
            // Buy & Sell Tax (Add or Remove Liquidity Included)
            if((from == uniswapV2Pair || to == uniswapV2Pair) && buySellTax > 0){
                taxAmount = amount * buySellTax / 1e4;
                super._transfer(from, address(this), taxAmount);
            }
        }

        if (!inSwapAndLiquify && to == uniswapV2Pair && !_isExcludedFromLimit[from]) {
            uint256 balance = balanceOf(address(this));
            if(balance >= swapAndLiqThreshold) {
                uint256 maxSwapAndLiq = swapAndLiqThreshold + (swapAndLiqThreshold / 5); //Additional 1.2*swapAndLiqThreshold
                if(balance >= maxSwapAndLiq){
                    swapAndLiquify(maxSwapAndLiq);
                }
                else {
                    swapAndLiquify(swapAndLiqThreshold);
                }
            }
        }

        super._transfer(from, to, (amount-taxAmount));
    }

    function setSellBuyTax(uint forMarketingInPercentage, uint forLiquidityInPercentage) external onlyOwner {
        
        uint256 taxInPercentage = forMarketingInPercentage + forLiquidityInPercentage;
        uint256 currentTaxInPercentage = buySellTax / 100;
        require(taxInPercentage <= currentTaxInPercentage, "You can only lower fees");

        

        ethFee = forMarketingInPercentage;
        liquidityFee = forLiquidityInPercentage;

        buySellTax = taxInPercentage * 100;
        
        emit TaxUpdated(buySellTax);
    }

    function setTradingOpen() external onlyOwner {
        require(!tradingOpen, "Trading already open");
        tradingOpen = true;
        emit TradingStatusUpdated(true);
    }

    function setPurchaseLimit(uint _limit) external onlyOwner {
        purchaseLimit = _limit;
        emit PurchaseLimitUpdated(_limit);
    }

    function setSwapAndLiqThreshold(uint256 amount) public onlyOwner {
        uint256 currentTotalSupply = totalSupply();
        uint256 minSwapAndLiqThreshold = currentTotalSupply / 10000; // 0.01% of the current total token supply
        uint256 maxSwapAndLiqThreshold = currentTotalSupply * 5 / 1000; // 0.5% of the current total token supply

        require(amount >= minSwapAndLiqThreshold && amount <= maxSwapAndLiqThreshold, "SnL Threshold must be within the allowed range");
        swapAndLiqThreshold = amount;
        emit SwapAndLiqThresholdSet(amount);
    }

    function excludeFromLimitation(address account, bool excluded) public onlyOwner {
        _isExcludedFromLimit[account] = excluded;
        emit ExcludeFromLimitation(account, excluded);
    }

    function batchExcludeFromLimitation(address[] calldata account, bool[] calldata excluded) public onlyOwner {
        for(uint i = 0 ; i < account.length ; i ++) {
            _isExcludedFromLimit[account[i]] = excluded[i];
        }
        emit BatchExcludeFromLimitation(account, excluded);
    }

    function withdrawETH(address payable _to) external onlyOwner {
        require(address(this).balance > 0, "No ETH to withdraw");
        uint256 amount = address(this).balance;
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit ETHWithdrawn(_to, amount);
    }

    function withdrawERC20Token(address token, address to) public onlyOwner {
        uint256 balance = IERC20(address(token)).balanceOf(address(this));
        require(balance > 0, "Not enough tokens in contract");
        IERC20(address(token)).transfer(to, balance);
        emit ERC20Withdrawn(to, balance);
    }
}