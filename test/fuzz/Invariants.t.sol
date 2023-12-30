//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/DeployDsc.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";
import {console} from "forge-std/console.sol";

contract Invariants is StdInvariant, Test {
    Handler public handler;
    DSCEngine public dsce;
    DeployDSC public deployer;
    DecentralizedStableCoin public dsc;
    HelperConfig helperConfig;
    address public weth;
    address public wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.ActiveNetworkConfig();
        handler = new Handler(dsce, dsc);

        // targetContract(address(dsce));
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = ERC20Mock(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = ERC20Mock(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

        console.log("weth amount:  %s", wethValue);
        console.log("wbtc amount:  %s", wbtcValue);
        console.log("total supply: %s", totalSupply);
        console.log("Time Mint Called: %s", handler.timeMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
