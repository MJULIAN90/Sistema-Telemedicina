// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;
import "../Token/ERC20.sol";
import "./IInsuranceRocketCompany.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./InsuranceClientRocketCompany.sol";
import "./InsuranceLaboratoryRocketCompany.sol";

contract InsuranceRocketCompany is InterfaceRocket{
    //Utilizamos la  libreria SafeMath para los tipos de datos uint16
    using SafeMath for uint16;

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
    function BalanceContractEthers ()public view returns(uint){
        return addressContract.balance;
    }

    //---------------------------------------Modifiers---------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner, "No tienes los permisos necesarios para ejecutar esta funcion");
        _;
    }

    modifier onlyLaboratories {
        //require (RequestStatus[msg.sender].requestType == uint16 (1)  /* && RequestStatus[msg.sender].statusRequest == true */ ,  "No posee permisos de laboratorio");
        require (true ,  "No posee permisos de laboratorio");
        _;
    }

    modifier onlyClient{
        require (true ,  "No posee permisos de laboratorio");
        _;        
    }

    //---------------------------------------Mappings---------------------------------------
    //Mapping para relacionar el nombre de un servicio con su estructura de datos
    mapping(string => Service) public Services;

    //Mapping para guardar los servicios especializados de laboratorios externos
    mapping(string => SpecialService)  public SpecialServices;

    //Mapping que relaciona la address con la peticion
    mapping(address => Request) public RequestStatus;

    //Mapping que relacion un address de cada usuario con su historial de servicios
    mapping(address => string []) public servicesClienteHistory;

    //---------------------------------------Enums---------------------------------------
    //Enum para clasificar el tipo de peticion de suscripcion
    enum RequestType { CLIENT, LABORATORY }

    //---------------------------------------Arrays---------------------------------------
    //Array para almacenar el listado de los servicios
    string[] public listServices;

    //Array para almacenar el listado de los servicios especiales de los laboratorios
    string[] public listSpecialServices;

    //Array para almacenar las peticiones de suscripcion de clientes
    address[] requestMixed;

    //---------------------------------------Funciones de tokens----------------------------------------------------

    //Funcion para recargar tokens al contrato
    function rechargeTokens(uint16 _amount) public override onlyOwner {
        token.mint(_amount);

        emit rechargeTokensEvent(_amount);
    }

    //Funcion ver tokens de contrato principal
    function balanceContractTokens () public view returns(uint){
        uint balance = token.balanceOf(addressContract);

        return balance;
    }

    //Funcion para convertir el precio de tokens a ethers
    function tokenToGwei(uint _quantity) private pure returns(uint){
        //return _quantity * (1 gwei);
        return _quantity * (1 gwei);
    } 

    //Funcion para comprar tokens
    function buyTokens(uint _quantity, address ownerClient  ) public payable {
        uint cost = tokenToGwei(_quantity);
        require(msg.value >= cost, "Necesitas mas ethers para comprar esta cantidad de tokens.");
        uint returnValue = msg.value - cost;
        payable(ownerClient).transfer(returnValue);
        token.transfer(msg.sender , _quantity );
    }

    //Funcion para recibir pagos
    receive() external payable{}
    fallback ()external payable{}

    //---------------------------------------Funciones para contrato principal---------------------------------------

    //Funcion para ver el listado de servicios activos
    function showActivedServices() public view override returns(string[] memory){
        string[] memory activedServices = new string[] (listServices.length);
        uint16 counter = 0;

        for(uint16 i = 0; i < listServices.length; i++){
            if(Services[listServices[i]].statusService == true){
                activedServices[counter] = listServices[i];
                counter++;
            }
        }

        return activedServices;       
    }

    //Funcion para ver el listado de servicios especiales activos
    function showActivedSpecialServices() public view returns(string[] memory){
        string[] memory activedServices = new string[] (listSpecialServices.length);
        uint16 counter = 0;

        for(uint16 i = 0; i < listSpecialServices.length; i++){
            if(SpecialServices[listSpecialServices[i]].statusService == true){
                activedServices[counter] = listSpecialServices[i];
                counter++;
            }
        }

        return activedServices;       
    }

    //Funcion para mostrar un servicio por su nombre
    //function showService(string memory _name) public view override returns(Service memory){return Services[_name];} 
    function showServiceDetails(string memory _name) public view override returns(string memory , uint16 , bool){
        return (_name , Services[_name].priceService , Services[_name].statusService);
    }

    //Funcion para mostrar un servicio por su nombre
    function showSpecialServiceDetails(string memory _name) public view  returns(string memory , uint16 , bool){
        return (_name , SpecialServices[_name].priceService , SpecialServices[_name].statusService);
    }

    //---------------------------------------Funciones para el admin---------------------------------------

    //Funcion para ver las solicitudes pendientes
    function showPendingRequest(string memory _type) public view override onlyOwner returns(address[] memory) {
        require(keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("Client")) || keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("Laboratory")), "El tipo ingresado no es correcto");
        
        uint16 counter;
        address[] memory pendingRequests = new address[] (requestMixed.length);

        if(keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("CLIENT"))){
            for(uint16 i = 0; i < requestMixed.length; i++){
                if(RequestStatus[requestMixed[i]].statusRequest == false){
                    pendingRequests[counter] = requestMixed[i];
                    counter++;
                }
            }
        }else{
            for(uint16 i = 0; i < requestMixed.length; i++){
                if(RequestStatus[requestMixed[i]].statusRequest == false){
                    pendingRequests[counter] = requestMixed[i];
                    counter++;
                }
            }
        }
        
        return pendingRequests;
    }

    //Funcion para habilitar un cliente o laboratorio
    function enableSubscription(address _addr) public override onlyOwner{
        RequestStatus[_addr].statusRequest = true;

        emit enableSubscriptionEvent("Se ha habilitado un cliente o suscripcion");
    }

    //Funcion para cambiar el estado de los servicios
    function changeStatusService(string memory _name) public override onlyOwner{
        Services[_name].statusService = !Services[_name].statusService;

        emit changeStatusServiceEvent("Se ha cambiado el estado del servicio correctamente.");
    }

    //Funcion para crear servicios
    function createService(string memory _name, uint16 _price) public override onlyOwner{
        Services[_name] = Service(_price, true);
        listServices.push(_name);
        emit createServiceEvent("Se ha creado un nuevo servicio.");
    }

    //---------------------------------------Contrato clientes---------------------------------------

    //Funcion para solicitar una suscripcion para un cliente
    function requestSubscriptionClient() public override onlyClient{
        RequestStatus[msg.sender] = Request(uint16(RequestType.CLIENT), false, address(0));
        requestMixed.push(msg.sender);
    }

    //Funcion para creacion de contrato de Cliente
    function createClientFactory() public onlyClient{
        //require(RequestStatus[msg.sender].statusRequest == true && RequestStatus[msg.sender].requestType == 0, "No tienes habilitado para crear tu contrato o tipo de contrato no coincide.");

        address clientAddressContract = address(new Client(msg.sender, addressContract));
        RequestStatus[msg.sender].addressContract = clientAddressContract;

        emit createFactoryEvent("Contrato creado", clientAddressContract);
    }

    //Funcion para ver saldo de Cliente
    function balanceClient(address _addr) public view onlyClient returns (uint){
        return token.balanceOf(_addr);
    }

    //Funcion cancelar contrato de un Client
    function cancelContractClient(address _userWallet) public payable onlyClient returns(string memory){
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
        
    //Funcion para revisar el numero de contrato de cada cliente
    function checkNumberContract() public view onlyClient returns(address){
        return RequestStatus[msg.sender].addressContract;
    }

    //Funcion para asginar un servicio a un cliente
    function asignServiceCliente(string memory _nameService) external onlyClient{
        require (Services[_nameService].statusService == true, "Servicio no disponible");
        require (Services[_nameService].priceService <= token.balanceOf(msg.sender), "No posee fondos sufiecientes");

        token.transferTokenRocket(msg.sender,addressContract, Services[_nameService].priceService);
        servicesClienteHistory[msg.sender].push(_nameService);

        emit asignServiceClienteEvent ("Servicio asginado correctamente" , msg.sender);
    }

    //Funcion para mostrar los servicios de un Cliente
    function showServicesCliente() external view onlyClient returns(string [] memory){
        return servicesClienteHistory[msg.sender];
    }

    //---------------------------------------Contratos laboratorios---------------------------------------

    //Funcion para solicitar una suscripcion para un laboratorio
    function requestSubscriptionLaboratory() public override {
        RequestStatus[msg.sender] = Request(uint16(RequestType.LABORATORY), false, address(0));
        requestMixed.push(msg.sender);
    }

    function createLaboratoryFactory() public {
        //require(RequestStatus[msg.sender].statusRequest == true && RequestStatus[msg.sender].requestType == 1, "No tienes habilitado para crear tu contrato o tipo de contrato no coincide.");

        address laboratoryAddressContract = address(new Laboratory(msg.sender , addressContract ));
        RequestStatus[msg.sender].addressContract = laboratoryAddressContract;

        emit createFactoryEvent("Contrato creado", laboratoryAddressContract);
    }

    //Funcion para crear servicios especiales
    function createSpecialService(string memory _name, uint16 _price) public onlyLaboratories {
        SpecialServices[_name] = SpecialService(_price, true , msg.sender);
        listSpecialServices.push(_name);
        emit createServiceEvent("Se ha creado un nuevo servicio especial.");
    }

    //Funcion para cambiar el estado de los servicios especiales
    function changeStatusServiceLaboratory(string memory _name) public onlyLaboratories{
        SpecialServices[_name].statusService = !SpecialServices[_name].statusService;

        emit changeStatusServiceEvent("Se ha cambiado el estado del servicio especial correctamente.");
    } 

    //Funcion cancelar contrato de laborario
    function cancelContractLaboratory(address _laboratory) public payable onlyLaboratories returns(string memory){
        Laboratory LaboratoryContract = Laboratory(msg.sender);
        LaboratoryContract.changeStatus ();

        if (token.balanceOf(msg.sender) > 0 ) {
            uint balanceLaboratyTokens = token.balanceOf(msg.sender);
            token.transferTokenRocket(msg.sender, addressContract, balanceLaboratyTokens );
            payable (_laboratory).transfer(tokenToGwei(balanceLaboratyTokens));

            return "Tu contrato ha sido cancelado y tu dinero devuelto a tu wallet";
        }else{
            return "Tu contrato ha sido cancelado";
        }
    }

    //Funcion para canjear sus tokens por dinero
    function withdrawBalanceLaboratory(address _laboratory , uint16 _quantityTokens) public payable onlyLaboratories returns(string memory){
        require (token.balanceOf(msg.sender) > 0 , "No posee balance suficiente");
 
            uint balanceLaboratyTokens = token.balanceOf(msg.sender);
            uint returnTokens = balanceLaboratyTokens - _quantityTokens;
            token.transferTokenRocket(msg.sender, addressContract, returnTokens );
            payable (_laboratory).transfer(tokenToGwei(returnTokens));

            return "tu retiro ha sido exitoso";
    } 

    //Funcion para asginar un servicio a un cliente
    function asignSpecialServiceCliente(string memory _nameService) external {
        require (SpecialServices[_nameService].statusService == true, "Servicio no disponible");
        require (SpecialServices[_nameService].priceService <= token.balanceOf(msg.sender), "No posee fondos sufiecientes");

        token.transferTokenRocket(msg.sender,SpecialServices[_nameService].laboratory , SpecialServices[_nameService].priceService);
        servicesClienteHistory[msg.sender].push(_nameService);

        emit asignServiceClienteEvent ("Servicio asginado correctamente" , msg.sender);
    }
}


