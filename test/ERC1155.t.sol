// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";

interface ERC1155 {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;
}

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();
    address alice;
    address bob;
    ERC1155 token;

    function setUp() public {
        alice = address(0x1);
        bob = address(0x2);
        token = ERC1155(yulDeployer.deployContract("ERC1155"));
    }

    function testMint() public {
        assertEq(token.balanceOf(alice, 0), 0);
        assertEq(token.balanceOf(alice, 1), 0);

        token.mint(alice, 0, 100, "");
        assertEq(token.balanceOf(alice, 0), 100);

        token.mint(alice, 1, 200, "");
        assertEq(token.balanceOf(alice, 1), 200);

        assertEq(token.balanceOf(alice, 2), 0);
    }

    function testTransfer() public {
        assertEq(token.balanceOf(alice, 3), 0);
        assertEq(token.balanceOf(bob, 3), 0);

        token.mint(alice, 3, 100, "");
        assertEq(token.balanceOf(alice, 3), 100);
        assertEq(token.balanceOf(bob, 3), 0);

        vm.prank(alice);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(alice, bob, 3, 50, "");
        assertEq(token.balanceOf(alice, 3), 50);
        assertEq(token.balanceOf(bob, 3), 50);
    }
}
