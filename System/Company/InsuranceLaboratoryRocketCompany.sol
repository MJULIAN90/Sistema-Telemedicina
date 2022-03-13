// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;
import "./InsuranceRocketCompany.sol";

contract Laboratory{
    address public owner;
    address private addressContract;
    bool public statusContract;
    InsuranceRocketCompany private IPrincipalContract;

    constructor(address _addr, address _addressContract) {
        owner = _addr;
        addressContract = address(this);
        IPrincipalContract =InsuranceRocketCompany(payable (_addressContract));
        statusContract = true;

    }

    //Funcion para devolver ether cuando un Cliente se da de baja
    function balanceUser () public  view returns(uint){
        require (statusContract , "No posee un contracto activo");
        return  IPrincipalContract.balanceClient(addressContract);
    }

    //Funcion cancelar contrato
    function changeStatus () external {
        statusContract = false;
    }

    //Funcion para crear los servicios ofrecidos
    function createSpecialService (string memory _name, uint16 _price) public {
        require (statusContract , "No posee un contracto activo");
        IPrincipalContract.createSpecialService(_name, _price);
    }

    //Funcion para cambiar el estado de los servicios especiales
    function changeStatusServiceLaboratory(string memory _name) public {
        require (statusContract , "No posee un contracto activo");
        IPrincipalContract.changeStatusServiceLaboratory(_name);
    }

    //Funcion cancelar contrato de laborario
    function cancelContractLaboratory() public{
        require (statusContract , "No posee un contracto activo");
        IPrincipalContract.cancelContractLaboratory(owner);
    }

    //Funcion para canjear sus tokens por dinero
    function withdrawBalanceLaboratory(uint16 _quantityTokens) public payable {
        require (statusContract , "No posee un contracto activo");
        IPrincipalContract.withdrawBalanceLaboratory(owner, _quantityTokens);
    }
    
}