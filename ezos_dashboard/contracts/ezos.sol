pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Ezos {

/***************************************************************************************/
/***************************************************************************************/
/********************************* VARIABLES START *************************************/
/***************************************************************************************/
/***************************************************************************************/

    string name;
    string symbol;
    uint8 decimals = 18;
    uint256 totalSupply;

    uint256 ezosGenesisBlock;
    uint256 lastBlock;

    uint256 miningReward;
    uint256 publicMineSupply;
    uint256 masternodeSupply;
    uint256 smallReward = 0;
    uint256 bigReward = 0;
    uint256 masternodeRate;

    uint256 staticFinney = 1 finney;

    uint256 failedMiningAttemps = 0;
    uint256 masterNodeBlocktime = 10;

    address owner;

    address ezos = 0xB8a33997F1eceA0191b520a8AEf82926F2c28Cf2;

    /*The higher, he harder to hit the block*/
    uint256 difficulty = 10;

/***************************************************************************************/
/***************************************************************************************/
/********************************** VARIABLES END **************************************/
/***************************************************************************************/
/***************************************************************************************/


/***************************************************************************************/
/***************************************************************************************/
/********************************** MAPPINGS START *************************************/
/***************************************************************************************/
/***************************************************************************************/

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (uint256 => bool) public blockHasBeenMined;

    mapping (address => bool) public masternodeCheck;
    mapping (address => uint256) public masternodeIndexInArray;


/***************************************************************************************/
/***************************************************************************************/
/********************************** MAPPINGS END ***************************************/
/***************************************************************************************/
/***************************************************************************************/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event ValueCheck(uint256 value);

/***************************************************************************************/
/***************************************************************************************/
/********************************** MODIFIERS START *************************************/
/***************************************************************************************/
/***************************************************************************************/

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMasterNode {
        require(masternodeCheck[msg.sender]);
        _;
    }

    modifier remainingNodeSupplyChecky{
        require(masternodeSupply > 0);
        _;
    }

    modifier remainingMineSupplyCheck{
        require(publicMineSupply > miningReward);
        _;
    }

    modifier nodePotentialCheck{
        require(!masternodeCheck[msg.sender]);
        require(balanceOf[msg.sender] > 10);
        _;
    }

/***************************************************************************************/
/***************************************************************************************/
/*********************************** MODIFIERS END *************************************/
/***************************************************************************************/
/***************************************************************************************/

/***************************************************************************************/
/***************************************************************************************/
/********************************* DATATYPES START *************************************/
/***************************************************************************************/
/***************************************************************************************/

    struct Masternode{
        address userAddress;
        uint256 registeredAt;
        uint256 lastTimeRewarded;
    }

    Masternode[] private masternode;

/***************************************************************************************/
/***************************************************************************************/
/*********************************** DATATYPES END *************************************/
/***************************************************************************************/
/***************************************************************************************/

/***************************************************************************************/
/***************************************************************************************/
/********************************* CONSTRUCTOR START ***********************************/
/***************************************************************************************/
/***************************************************************************************/

    constructor() public {
        totalSupply = 210000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;                // Give the creator all initial tokens
        name = "Ezos";                                   // Set the name for display purposes
        symbol = "LILK";                               // Set the symbol for display purposes
        ezosGenesisBlock = block.number;
        lastBlock = block.number;
        publicMineSupply = SafeMath.div(totalSupply,2);
        masternodeSupply = SafeMath.sub(totalSupply, publicMineSupply);
        owner = msg.sender;
        masternodeRate = 7;
        miningReward = 50 * 10 ** uint256(decimals);
    }

/***************************************************************************************/
/***************************************************************************************/
/*********************************** CONSTRUCTOR END ***********************************/
/***************************************************************************************/
/***************************************************************************************/

    function getStaticFinney() public view returns (uint){
        return staticFinney;
    }

/***************************************************************************************/
/***************************************************************************************/
/************************************ MINING START *************************************/
/***************************************************************************************/
/***************************************************************************************/

    function calcSmallReward(uint256 _miningReward) private pure returns(uint256 _reward){
        _reward=SafeMath.div(SafeMath.mul(_miningReward, 20),100);
        return _reward;
    }

     function calcBigReward(uint256 _miningReward) private pure returns(uint256 _reward){
        _reward=SafeMath.div(SafeMath.mul(_miningReward, 80),100);
        return _reward;
    }

    function publicMine() public payable remainingMineSupplyCheck{

        miningReward = getCurrentMiningReward();
        smallReward = calcSmallReward(miningReward);

        if(msg.value > staticFinney) {
            this.transfer(msg.sender, smallReward);
            this.transfer(ezos, smallReward);
            ezos.transfer(msg.value);
            publicMineSupply = SafeMath.sub(publicMineSupply,smallReward);
        }

        if(msg.value < staticFinney){

            if(testRandomCheck() == false){

                failedMiningAttemps += 1;

            }

            if(testRandomCheck() == true){

                bigReward = calcBigReward(miningReward);

                if(blockHasBeenMined[block.number] == false){

                blockHasBeenMined[block.number] = true;

                this.transfer(msg.sender, bigReward);
                this.transfer(ezos, smallReward);

                publicMineSupply = SafeMath.sub(publicMineSupply,miningReward);

                }
            }
        }
    }

    function generateRandomNumber() public view returns(uint256 _test){
        uint newNounce = uint(blockhash(block.number-1))%difficulty + 1;
        return newNounce;
    }

    function testRandomCheck() public view returns (bool){
        uint256 nounce = generateRandomNumber();
        if (nounce > 5){
            return true;
        } else {
            return false;
        }
    }

    function getRemainingPublicMineSupply() public view returns (uint256 _amount){
        return publicMineSupply;
    }

    function getRemainingMasternodeSupply() public view returns (uint256 _amount){
        return masternodeSupply;
    }

/***************************************************************************************/
/***************************************************************************************/
/************************************ MINING START *************************************/
/***************************************************************************************/
/***************************************************************************************/

/***************************************************************************************/
/***************************************************************************************/
/********************************** MASTERNODE START ***********************************/
/***************************************************************************************/
/***************************************************************************************/

    function registerMasternode() public nodePotentialCheck{

        uint256 currentEzosBlock = getCurrentEzosBlock();

        Masternode memory _masternode = Masternode({
            userAddress: msg.sender,
            registeredAt: currentEzosBlock,
            lastTimeRewarded: currentEzosBlock
        });

        masternodeCheck[msg.sender] = true;

        masternode.push(_masternode);

        masternodeIndexInArray[msg.sender] = SafeMath.sub(masternode.length,1);

    }

    function claimMasternodeReward() public onlyMasterNode remainingNodeSupplyChecky{

        uint256 interest = amountToClaim(msg.sender);

        this.transfer(msg.sender, interest);

        masternode[masternodeIndexInArray[msg.sender]].lastTimeRewarded = getCurrentEzosBlock();

        masternodeSupply = SafeMath.sub(masternodeSupply, interest);

    }

    function amountToClaim(address _owner) private view returns(uint256 rate){

        uint256 blockstopay = SafeMath.sub(getCurrentEzosBlock(),masternode[masternodeIndexInArray[_owner]].lastTimeRewarded);

        uint256 rewardTimes = SafeMath.div(blockstopay, masterNodeBlocktime);

        for (uint256 x = 0; x < rewardTimes; x++){
            rate = SafeMath.add(rate, SafeMath.div(SafeMath.mul(balanceOf[_owner], masternodeRate),100));
        }

        return rate;
    }

    function getCurrentPossibleAmountOfAddress(address _owner) public view returns(uint256 _amount){

         if(!masternodeCheck[_owner]){
            _amount = 0;
        }

        if(masternodeCheck[_owner]){
         uint256 blockstopay = SafeMath.sub(getCurrentEzosBlock(),masternode[masternodeIndexInArray[_owner]].lastTimeRewarded);

        uint256 rewardTimes = SafeMath.div(blockstopay, masterNodeBlocktime);

        for (uint256 x = 0; x < rewardTimes; x++){
            _amount = SafeMath.add(_amount, SafeMath.div(SafeMath.mul(balanceOf[_owner], masternodeRate),100));
        }
        }

         return _amount;
    }

    function unclaimedEzos (address _owner) public view returns(uint256 _amount){

        if(!masternodeCheck[_owner]){
            _amount = 0;
        }

        if(masternodeCheck[_owner]){
         uint256 blockstopay = SafeMath.sub(getCurrentEzosBlock(),masternode[masternodeIndexInArray[_owner]].lastTimeRewarded);

        uint256 rewardTimes = SafeMath.div(blockstopay, masterNodeBlocktime);

        for (uint256 x = 0; x < rewardTimes; x++){
            _amount = SafeMath.add(_amount, SafeMath.div(SafeMath.mul(balanceOf[_owner], masternodeRate),100));
        }
        }

         return _amount;
    }

    function getLastTimeRewarded(address _owner) public view returns (uint256 _block){
        uint256 index = masternodeIndexInArray[_owner];
        return masternode[index].lastTimeRewarded;

    }

    function checkForMasterNode(address _owner) public view returns (bool _state){
       _state = masternodeCheck[_owner];
       return _state;
    }

/***************************************************************************************/
/***************************************************************************************/
/********************************** MASTERNODE END *************************************/
/***************************************************************************************/
/***************************************************************************************/

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function getCurrentEthBlock() private view returns (uint256 blockAmount){
        return block.number;
    }

    function getCurrentEzosBlock() public view returns (uint256){
        uint256 eth = getCurrentEthBlock();
        uint256 ezosBlock = eth - ezosGenesisBlock;
        return ezosBlock;
    }

    function getCurrentMiningReward() public view returns(uint256 _miningReward){
        return miningReward;
    }

     function getCurrentMasterNodeReward() public view returns(uint256 _miningReward){
        return masternodeRate;
    }

    function getCurrentDif() public view returns (uint256 _dif){
        return difficulty;
    }

    function adjustRewards() public {
        uint256 _currentEzosBlock = getCurrentEzosBlock();

        if(_currentEzosBlock > 10 && _currentEzosBlock <100){
            miningReward = 40 * 10 ** uint256(decimals);
            masternodeRate = 5;
        }

        if(_currentEzosBlock > 100 && _currentEzosBlock <1000){
             miningReward = 30 * 10 ** uint256(decimals);
            masternodeRate = 4;
        }
        if(_currentEzosBlock > 1000 && _currentEzosBlock <10000){
             miningReward = 20 * 10 ** uint256(decimals);
            masternodeRate = 3;
        }

    }

    function adjustDifficulty(uint256 _diff) public onlyOwner  {
        difficulty = _diff;
    }
}

/*********************************/
/*********** CALC LIB ************/
/*********************************/

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
