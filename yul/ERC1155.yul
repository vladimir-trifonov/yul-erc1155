object "ERC1155" {
  code {
    // Store the creator in slot zero.
    sstore(0, caller())

    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      // Protection against sending Ether
      if gt(callvalue(), 0) {
          revert(0, 0)
      }

      switch selector()
      case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
        returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
      }
      case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
        balanceOfBatch(decodeAsUint(0), decodeAsUint(1))
      }
      case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
        _mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3))
      }
      case 0x1f7fDffa /* mintBatch(address,uint256[],uint256[],bytes) */{
        _mintBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3))
      }
      case 0xf5298aca /* burn(address,uint256,uint256) */ {
        _burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
      }
      case 0x6b20c454 /* burnBatch(address,uint256[],uint256[]) */ {
        _burnBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
      }
      case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
        safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
      }
      case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
        safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
      }
      case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
        setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
      }
      case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
        returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
      }
      case 0x0e89341C /* uri(uint256) */ {
        uri(decodeAsUint(0))
      } 
      case 0x02fe5305 /* setURI(string) */ {
        _setURI(decodeAsUint(0))
      }
      default {
        revert(0, 0)
      }

      /* -------- storage layout ---------- */

      function uriLenPos() -> p { p := 0 }

      function balanceStorageOffset(id, account) -> offset {
        mstore(0x00, 0x01) // Slot 1
        mstore(0x20, id)
        mstore(0x40, account)
        offset := keccak256(0, 0x60)
      }

      function approvalForAllStorageOffset(owner, operator) -> offset {
        mstore(0x00, 0x02) // Slot 2
        mstore(0x20, owner)
        mstore(0x40, operator)
        offset := keccak256(0, 0x60)
      }

      /* ----------  dispatcher functions ---------- */
      function uri(id) {
        let oldMptr := mload(0x40)
        let mptr := oldMptr

        mstore(mptr, 0x20)
        mptr := add(mptr, 0x20)

        let uriLen := sload(uriLenPos())
        mstore(mptr, uriLen)
        mptr := add(mptr, 0x20)

        let bound := div(uriLen, 0x20)
        if mod(bound, 0x20) {
            bound := add(bound, 1)
        }

        mstore(0x00, uriLen)
        let firstSlot := keccak256(0x00, 0x20)

        for { let i := 0 } lt(i, bound) { i := add(i, 1) } {
            let str := sload(add(firstSlot, i))
            mstore(mptr, str)
            mptr := add(mptr, 0x20)
        }

        return(oldMptr, sub(mptr, oldMptr))
      }

      function balanceOf(account, id) -> bal {
        bal := sload(balanceStorageOffset(id, account))
      }

      /* -------- events ---------- */
      function emitTransferSingle(operator, from, to, id, value) {
        /* TransferSingle(address,address,address,uint256) */
        let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        mstore(0x00, id)
        mstore(0x20, value)
        log4(0x00, 0x40, signatureHash, operator, from, to)
      }

      function emitApprovalForAll(owner, operator, approved) {
        /* ApprovalForAll(adderss,address,bool) */
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        mstore(0x00, approved)
        log3(0x00, 0x20, signatureHash, owner, operator)
      }

      function emitTransferBatch(operator, from, to, idsOffset, valuesOffset) {
      }

      /* ---------- calldata decoding functions ----------- */
      
      function selector() -> s {
        s := shr(0xE0, calldataload(0))
      }

      function decodeAsUint(offset) -> v {
        let pos := add(4, mul(offset, 0x20))
        if lt(calldatasize(), add(pos, 0x20)) {
            revert(0, 0)
        }
        v := calldataload(pos)
      }

      function decodeAsAddress(offset) -> v {
        v := decodeAsUint(offset)
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
        }
      }

      function decodeAsArrayLen(offset) -> len {
        len := calldataload(add(4, offset))
      }

      /* ---------- calldata encoding functions ---------- */

      function returnUint(v) {
        mstore(0, v)
        return(0, 0x20)
      }

      /* -------- storage access ---------- */

      function balanceOfBatch(accountsOffset, idsOffset) {
        let accountsLen := decodeAsArrayLen(accountsOffset)
        let idsLen := decodeAsArrayLen(idsOffset)

        if require(eq(accountsLen, idsLen)) 
        {   
          revert(0, 0)
        }

        let mptr := 0x80
        mstore(mptr, 0x20)
        mptr := add(mptr, 0x20)

        mstore(mptr, accountsLen)
        mptr := add(mptr, 0x20)

        let accountsStartOffset := add(accountsOffset, 0x24) 
        let idsStartOffset := add(idsOffset, 0x24) 

        for { let i := 0 } lt(i, accountsLen) { i:= add(i, 1)}
        {    
          let account := calldataload(add(accountsStartOffset, mul(0x20, i)))
          let id := calldataload(add(idsStartOffset, mul(0x20, i)))
          mstore(mptr, balanceOf(account, id)) 
          mptr := add(mptr, 0x20)
        }

        return(0x80, sub(mptr, 0x80))

      }

      function setApprovalForAll(operator, id) {
        _setApprovalForall(caller(), operator, id)
      }

      function _setApprovalForall(owner, operator, approved) {
        let offset := approvalForAllStorageOffset(owner, operator)
        sstore(offset, approved)

        emitApprovalForAll(owner, operator, approved)
      }

      function isApprovedForAll(account, operator) -> v {
        let offset := approvalForAllStorageOffset(account, operator)
        v := sload(offset)
      }

      function safeTransferFrom(from, to, id, amount, dataOffset) {
        if require(or(eq(from, caller()), isApprovedForAll(from, caller()))) {
          revert(0, 0)
        }
        _safeTransferFrom(from, to, id, amount, dataOffset)
      }

      function _safeTransferFrom(from, to, id, amount, dataOffset) {
        if require(gte(balanceOf(from, id), amount)) {
          revert(0, 0)
        }
        _subBalance(from, id, amount)
        _addBalance(to, id, amount)

        emitTransferSingle(caller(), from, to, id, amount)
      }

      function safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset) {
        if require(or(eq(from, caller()), isApprovedForAll(from, caller()))) {
          revert(0, 0)
        }
        _safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset)
      }

      function _safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset) {
        let idsLen := decodeAsArrayLen(idsOffset)
        let amountsLen := decodeAsArrayLen(amountsOffset)

        if require(eq(idsLen, amountsLen)) {
          revert(0, 0)
        }

        if require(to) {
          revert(0, 0)
        }

        let firstIdPtr := add(idsOffset, 0x24)          
        let firstAmountPtr := add(amountsOffset, 0x24) 

        for { let i := 0} lt(i, idsLen) { i := add(i, 1) }
        {
          let id := calldataload(add(firstIdPtr, mul(i, 0x20)))
          let amount := calldataload(add(firstAmountPtr, mul(i, 0x20)))

          let fromBalance := sload(balanceStorageOffset(id, from))

          if require(gte(fromBalance, amount)) {
            revert(0, 0)
          }

          _subBalance(from, id, amount)
          _addBalance(to, id, amount)
        }

        emitTransferBatch(caller(), from, to, idsOffset, amountsOffset)
      }

      function _mint(to, id, amount, dataOffset) {
        _addBalance(to, id, amount)
        emitTransferSingle(caller(), 0, to, id, amount)
      }

      function _mintBatch(to, idsOffset, amountsOffset, dataOffset) {
        let idsLen := decodeAsArrayLen(idsOffset)
        let amountsLen := decodeAsArrayLen(amountsOffset)

        let idsStartPtr := add(idsOffset, 0x24)
        let amountsStartPtr := add(amountsOffset, 0x24)

        for { let i := 0 } lt(i, idsLen) { i := add(i, 1)}
        {
            let id := calldataload(add(idsStartPtr, mul(0x20, i)))
            let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))
            _addBalance(to, id, amount)
        }

        emitTransferBatch(caller(), 0, to, idsOffset, amountsOffset)
      }

      function _burn(from, id, amount) {
        let fromBalance := sload(balanceStorageOffset(id, from))
        _subBalance(from, id, amount)

        emitTransferSingle(caller(), from, 0, id, amount)
      }

      function _burnBatch(from, idsOffset, amountsOffset) {
        let idsLen := decodeAsArrayLen(idsOffset)
        let amountsLen := decodeAsArrayLen(amountsOffset)

        let idsStartPtr := add(idsOffset, 0x24)
        let amountsStartPtr := add(amountsOffset, 0x24)

        for { let i:= 0 } lt(i, idsLen) { i := add(i, 1)}
        {
          let id := calldataload(add(idsStartPtr, mul(0x20, i)))
          let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))

          let fromBalance := sload(balanceStorageOffset(id, from))
          
          _subBalance(from, id, amount)
        }

        emitTransferBatch(caller(), from, 0, idsOffset, amountsOffset)
      }

      function _addBalance(to, id, amount) {
        let offset := balanceStorageOffset(id, to)
        let prev := sload(offset)
        sstore(offset, add(prev, amount))
      }

      function _subBalance(to, id, amount) {
        let offset := balanceStorageOffset(id, to)
        let prev := sload(offset)
        sstore(offset, sub(prev, amount))
      }

      function _setURI(strOffset) {
        let oldStrLen := sload(uriLenPos())
        mstore(0x00, oldStrLen)
        let oldStrFirstSlot := keccak256(0x00, 0x20)

        if oldStrLen {
            let bound := div(oldStrLen, 0x20)

            if mod(oldStrLen, 0x20) {
                bound := add(bound, 1)
            }

            for { let i := 0 } lt(i, bound) { i := add(i, 1)}
            {
              sstore(add(oldStrFirstSlot, i), 0)
            }
        }

        let strLen := decodeAsArrayLen(strOffset)

        sstore(uriLenPos(), strLen) // store length of uri

        let strFirstPtr := add(strOffset, 0x24)

        mstore(0x00, strLen)
        let strFirstSlot := keccak256(0x00, 0x20)

        let bound := div(strLen, 0x20)
        if mod(strLen, 0x20) {
          bound := add(bound, 1)
        }

        for { let i := 0 } lt(i, bound) { i := add(i, 1) }
        {
          let str := calldataload(add(strFirstPtr, mul(0x20, i)))
          sstore(add(strFirstSlot, i), str)
        }
      }

      /* ---------- utility functions ---------- */

      function gte(a, b) -> r {
        r := iszero(lt(a, b))
      }

      function require(condition) -> res {
        res := iszero(condition)
      }
    }
  }
}