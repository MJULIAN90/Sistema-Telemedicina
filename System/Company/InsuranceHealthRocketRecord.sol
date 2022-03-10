// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;
import "../Token/ERC20.sol";
import "./IInsuranceRocketCompany.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract InsuranceRocketCompany is InterfaceRocket{
    //Utilizamos la  libreria SafeMath para los tipos de datos uint
    using SafeMath for uint;

    //Token
    ERC20Rocket token;
    address private owner;
    address public addressContract;

    constructor() {
        token = new ERC20Rocket("MedicineRocket", "MR");
        token.mint(10000);

        owner = msg.sender;
        addressContract = address(this);
    }

    //Funcion Ether balance
    function Balance ()public view returns(uint){
        return addressContract.balance;
    }

    //---------------------------------------Modifiers---------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner, "No tienes los permisos necesarios para ejecutar esta funcion");
        _;
    }

    //---------------------------------------Mappings---------------------------------------
    //Mapping para relacionar el nombre de un servicio con su estructura de datos
    mapping(string => Service) public Services;

    //Mapping que relaciona la address con la peticion
    mapping(address => Request) public RequestStatus;

    //---------------------------------------Enums---------------------------------------
    //Enum para clasificar el tipo de peticion de suscripcion
    enum RequestType { CLIENT, LABORATORY }

    //---------------------------------------Arrays---------------------------------------
    //Array para almacenar el listado de los servicios
    string[] public listServices;

    //Array para almacenar las peticiones de suscripcion de clientes
    address[] requestMixed;

    //---------------------------------------Funciones de tokens----------------------------------------------------

    //Funcion para recargar tokens al contrato
    function rechargeTokens(uint _amount) public override onlyOwner {
        token.mint(_amount);

        emit rechargeTokensEvent(_amount);
    }

    //Funcion ver tokens de contrato principal
    function balanceContract () public view returns(uint){
        uint balance = token.balanceOf(addressContract);

        return balance;
    }

    //Funcion para convertir el precio de tokens a ethers
    function tokenToGwei(uint _quantity) public pure returns(uint){
        //return _quantity * (1 gwei);
        return _quantity * (1 ether);
    } 

    //Funcion para comprar tokens
    function buyTokens(uint _quantity  ) public payable {
        uint cost = tokenToGwei(_quantity);
        require(msg.value >= cost, "Necesitas mas ethers para comprar esta cantidad de tokens.");

        token.transfer(msg.sender , _quantity );

        //uint returnValue = msg.value - cost;
        //payable(msg.sender).transfer(_quantity);
    }

    //Funcion para recibir pagos
    receive() external payable{}
    fallback ()external payable{}

    //---------------------------------------Funciones para contrato principal---------------------------------------

    //Funcion para ver el listado de servicios activos
    function showActivedServices() public view override returns(string[] memory){
        string[] memory activedServices = new string[] (listServices.length);
        uint counter = 0;

        for(uint i = 0; i < listServices.length; i++){
            if(Services[listServices[i]].statusService == true){
                activedServices[counter] = listServices[i];
                counter++;
            }
        }

        return activedServices;       
    }

    //Funcion para mostrar un servicio por su nombre
    //function showService(string memory _name) public view override returns(Service memory){return Services[_name];} 
    function showService(string memory _name) public view override returns(string memory , uint , bool){
        return (_name , Services[_name].priceService , Services[_name].statusService);
    }
    
    //Funcion para revisar el numero de contrato principal
    function checkNumberContract() public view returns(address){
        return RequestStatus[msg.sender].addressContract;
    }

    //---------------------------------------Funciones para el admin---------------------------------------

    //Funcion para ver las solicitudes pendientes
    function showPendingRequest(string memory _type) public view onlyOwner override returns(address[] memory) {
        require(keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("Client")) || keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("Laboratory")), "El tipo ingresado no es correcto");
        
        uint counter;
        address[] memory pendingRequests = new address[] (requestMixed.length);

        if(keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("CLIENT"))){
            for(uint i = 0; i < requestMixed.length; i++){
                if(RequestStatus[requestMixed[i]].statusRequest == false){
                    pendingRequests[counter] = requestMixed[i];
                    counter++;
                }
            }
        }else{
            for(uint i = 0; i < requestMixed.length; i++){
                if(RequestStatus[requestMixed[i]].statusRequest == false){
                    pendingRequests[counter] = requestMixed[i];
                    counter++;
                }
            }
        }
        
        return pendingRequests;
    }

    //Funcion para habilitar un cliente o laboratorio
    function enableSubscription(address _addr) public onlyOwner override {
        RequestStatus[_addr].statusRequest = true;

        emit enableSubscriptionEvent("Se ha habilitado un cliente o suscripcion");
    }

    //Funcion para cambiar el estado de los servicios
    function changeStatusService(string memory _name) public override onlyOwner{
        Services[_name].statusService = !Services[_name].statusService;

        emit changeStatusServiceEvent("Se ha cambiado el estado del servicio correctamente.");
    }

    //Funcion para crear servicios
    function createService(string memory _name, uint _price) public override onlyOwner{
        Services[_name] = Service(_price, true);
        listServices.push(_name);
        emit createServiceEvent("Se ha creado un nuevo servicio.");
    }

    //---------------------------------------Contrato clientes---------------------------------------

    //Funcion para solicitar una suscripcion para un cliente
    function requestSubscriptionClient() public override {
        RequestStatus[msg.sender] = Request(uint(RequestType.CLIENT), false, address(0));
        requestMixed.push(msg.sender);
    }

    //Funcion para creacion de contrato de usuarios
    function createClientFactory() public {
        //require(RequestStatus[msg.sender].statusRequest == true && RequestStatus[msg.sender].requestType == 0, "No tienes habilitado para crear tu contrato o tipo de contrato no coincide.");

        address clientAddressContract = address(new Client(msg.sender, addressContract));
        RequestStatus[msg.sender].addressContract = clientAddressContract;

        emit createFactoryEvent("Contrato creado", clientAddressContract);
    }

    //Funcion para ver saldo de usuarios
    function balanceUsers(address _addr) public view returns (uint){
        return token.balanceOf(_addr);
    }

    //Funcion cancelar contrato de un usuario
    function cancelContractUser(address _userWallet) public payable returns(string memory){
        Client ClientContract = Client(msg.sender);
        ClientContract.changeStatus ();

        if (token.balanceOf(msg.sender) > 0 ) {
            uint balanceUserTokens = token.balanceOf(msg.sender);
            token.transferTokenRocket(msg.sender,addressContract, balanceUserTokens );
            payable (_userWallet).transfer(tokenToGwei(balanceUserTokens));

            return "Tu contrato ha sido cancelado y tu dinero devuelto a tu wallet";
        }else{
            return "Tu contrato ha sido cancelado";
        }
    }

    //---------------------------------------Contratos laboratorios---------------------------------------

    //Funcion para solicitar una suscripcion para un laboratorio
    function requestSubscriptionLaboratory() public override {
        RequestStatus[msg.sender] = Request(uint(RequestType.LABORATORY), false, address(0));
        requestMixed.push(msg.sender);
    }

    function createLaboratoryFactory() public {
        require(RequestStatus[msg.sender].statusRequest == true && RequestStatus[msg.sender].requestType == 1, "No tienes habilitado para crear tu contrato o tipo de contrato no coincide.");

        address laboratoryAddressContract = address(new Laboratory(msg.sender));
        RequestStatus[msg.sender].addressContract = laboratoryAddressContract;

        emit createFactoryEvent("Contrato creado", laboratoryAddressContract);
    }
}

contract Client{
    address public owner;
    address private addressContract;
    address public addressPrincipalContract;
    bool public statusContract;
    InsuranceRocketCompany private IPrincipalContract;

    constructor(address _addr , address _addressContract ) {
        owner = _addr;
        addressContract = address(this);
        addressPrincipalContract= _addressContract;
        IPrincipalContract =InsuranceRocketCompany(payable (addressPrincipalContract));
        statusContract = true;
    }
    
    //Funcion cancelar contrato
    function changeStatus () external {
        statusContract = false;
    }

    //---------------------------------------Funciones contrato clientes---------------------------------------
    //Funcion para comprar tokens
    function buyTokens(uint _quantity) public payable {
        require (statusContract , "No posee un contracto activo");
        IPrincipalContract.buyTokens{value: msg.value}(_quantity);

    }

    //Funcion para devolver ether cuando un usuario se da de baja
    function balanceUser () public  view returns(uint){
        require (statusContract , "No posee un contracto activo");
        return  IPrincipalContract.balanceUsers(addressContract);
    }

    //Funcion para ver servicios disponibles
    function listServices () public view returns(string[] memory){
        require (statusContract , "No posee un contracto activo");
        return IPrincipalContract.showActivedServices();
    }

    //Funcion ver detalles de un servicio
    function detailsService (string memory _name) public  view returns(string memory , uint , bool){
       require (statusContract , "No posee un contracto activo");
       return (IPrincipalContract.showService(_name));
    }

    //Funcion para cancelar mi contrato
    function cancelContract () public payable returns(string memory){
       require (statusContract , "No posee un contracto activo a cancelar");
       return (IPrincipalContract.cancelContractUser(owner));
    }

}

contract Laboratory{
    address public owner;
    address private addressContract;

    constructor(address _addr) {
        owner = _addr;
        addressContract = address(this);
    }

    //Funcion para devolver ether cuando un usuario se da de baja

    //Funcion para crear los servicios ofrecidos
}