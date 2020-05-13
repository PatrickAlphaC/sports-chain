pragma solidity ^0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/ChainlinkClient.sol";
// there is always a msg global variable object, that comes from the sender

contract daily_unlimited_deFitasy is ChainlinkClient{
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    uint256 public game_id;
    uint256 public minutes_to_close;
    uint256 public minutes_to_pay;
    uint256 public team_one_id;
    uint256 public team_two_id;
    bool public open;
    uint256 datetime;
    uint256 public number_of_nba_players;
    address[] best_players;
    address public owner;
    
    string public test_url;
    
    string JOB_START_ID = "04e9b0ebd3c94ddda006d9fb23e2cdf9";
    string JOB_TIME_ID = "2d72ac14807c40ce94e79a6cc00b4777";
    address ORACLE = 0x241F77325C073a3815985691f76B58dff17F685B;
    
    struct entry {
        uint256[5] players;
        address my_address;
    }
    
    struct NBA_Player {
        uint256 id;
        //string name;
        uint256 points;
    }
    
    uint256 public total_entries = 0;
    uint256 POINT_ONE_ETH = 100000000000000000;
    entry[] deFitasy_entries;
    //mapping(uint256 => NBA_Player) NBA_Players;
    NBA_Player[] NBA_Players;
    
    //constructor(address aggregator) public{
        //time_aggregator = aggregator;
    constructor() public{
        setPublicChainlinkToken();
        owner = msg.sender;
    }
    
    function start_game() public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_START_ID), address(this), 
            this.fulfillStartGame.selector);
        req.add("url", "matches/upcoming?");
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }
    
    function fulfillStartGame(bytes32 _requestId, uint256 _game_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        game_id = _game_id;
        get_close_datetime();
        //get_nba_players();
    }
    
    
    ///////////////////////////////////////////////
    function get_close_datetime() public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), 
            address(this), this.fulfillCloseDateTime.selector);
        //abi.encodePacked(a, b)
        // bytes url = abi.encodePacked(bytes("matches/"), " ", bytes(game_id));
        // url = abi.encodePacked(url, bytes("?"));
        string memory url = concate("matches/", uint2str(game_id));
        string memory url_extended = concate(url, "?");
        test_url = url;
        req.add("url", url_extended);
        req.add("close", "true");
        req.add("copyPath", "minutes");
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }

    function fulfillCloseDateTime(bytes32 _requestId, uint256 _minutes_to_close)
    public
    recordChainlinkFulfillment(_requestId)
    {
        minutes_to_close = _minutes_to_close;
        get_payout_datetime();
    }
    //////////////////////////////////
    function get_payout_datetime() public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), address(this), this.fulfillPayoutDateTime.selector);
        string memory url = concate("matches/", uint2str(game_id));
        string memory url_extended = concate(url, "?");
        req.add("url", url_extended);
        req.add("payperiod", "true");
        req.add("copyPath", "minutes");
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }

    function fulfillPayoutDateTime(bytes32 _requestId, uint256 _minutes_to_pay)
    public
    recordChainlinkFulfillment(_requestId)
    {
        minutes_to_pay = _minutes_to_pay;
        set_close_alarm(0xc99B3D447826532722E41bc36e644ba3479E4365, stringToBytes32("2ebb1c1a4b1e4229adac24ee0b5f784f"));
        set_pay_alarm(0xc99B3D447826532722E41bc36e644ba3479E4365, stringToBytes32("2ebb1c1a4b1e4229adac24ee0b5f784f"));
        get_nba_teams1();
    }
    ////////////
    function set_close_alarm( address _oracle, bytes32 _jobId) public{
        //Oracle address: 0xc99B3D447826532722E41bc36e644ba3479E4365
        //JobID: 2ebb1c1a4b1e4229adac24ee0b5f784f
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfillCloseAlarm.selector);
        req.addUint("until", now + (minutes_to_close * 60));
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillCloseAlarm(bytes32 _requestId, uint256 _game_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        close_entry();
    }
    ////////////////
    

    function set_pay_alarm( address _oracle, bytes32 _jobId) public{
        //Oracle address: 0xc99B3D447826532722E41bc36e644ba3479E4365
        //JobID: 2ebb1c1a4b1e4229adac24ee0b5f784f
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfillPayAlarm.selector);
        req.addUint("until", now + (minutes_to_close * 60) );
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillPayAlarm(bytes32 _requestId, uint256 _game_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        get_winners();
    }
    //////////////////
    
    function get_nba_teams1() public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), address(this), this.fulfillNBATeams1.selector);
        string memory url = concate("matches/", uint2str(game_id));
        string memory url_extended = concate(url, "?");
        req.add("url", url_extended);
        req.add("copyPath", "opponents.0.opponent.id");
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }
    function fulfillNBATeams1(bytes32 _requestId, uint256 _team_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        team_two_id = _team_id;
        get_nba_teams2();
    }
    ////////////
    function get_nba_teams2() public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), address(this), this.fulfillNBATeams2.selector);
        string memory url = concate("matches/", uint2str(game_id));
        string memory url_extended = concate(url, "?");
        req.add("url", url_extended);
        req.add("copyPath", "opponents.1.opponent.id");
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }
    function fulfillNBATeams2(bytes32 _requestId, uint256 _team_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        team_two_id = _team_id;
        // We are assuming each has 5 players 
        for (uint i=0; i<5; i++) {
            get_team1_player_id(i);
            get_team2_player_id(i);
        }
    }
    ////////////////
    function get_team1_player_id(uint256 i) public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), address(this), this.fulfillNBATeams1.selector);
        string memory url = concate("teams/", uint2str(team_one_id));
        string memory url_extended = concate(url, "?");
        req.add("url", url_extended);
        string memory path = concate("players", uint2str(i));
        path = concate(path, "id");
        req.add("copyPath", path);
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }
    function fulfillNBAPlayers1(bytes32 _requestId, uint256 _player_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        NBA_Players.push(NBA_Player(_player_id, 0));
    }
    ///////////////
    ////////////////
    function get_team2_player_id(uint256 i) public{
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(JOB_TIME_ID), 
            address(this), this.fulfillNBATeams2.selector);
        string memory url = concate("teams/", uint2str(team_one_id));
        string memory url_extended = concate(url, "?");
        req.add("url", url_extended);
        string memory path = concate("players", uint2str(i));
        path = concate(path, "id");
        req.add("copyPath", path);
        sendChainlinkRequestTo(ORACLE, req, ORACLE_PAYMENT);
    }
    function fulfillNBAPlayers2(bytes32 _requestId, uint256 _player_id)
    public
    recordChainlinkFulfillment(_requestId)
    {
        NBA_Players.push(NBA_Player(_player_id, 0));
    }
    ///////////////

    function enter(uint256[5] memory picked_players_ids) public payable{
        // Enters the competition
        // Any number of players can enter
        assert(open);
        assert(msg.value == POINT_ONE_ETH);
        deFitasy_entries.push(entry(picked_players_ids, msg.sender));
        total_entries +=1;
    }
    
    function get_players() public view returns(uint256){
        return total_entries;
    }
    
    function get_winners() public{
        require(deFitasy_entries.length > 0);
        for(uint i = 0; i< NBA_Players.length; i++){
            NBA_Players[i].points = get_points_nba_players(NBA_Players[i].id);
        }
        uint max_points = 0;
        best_players.push(deFitasy_entries[0].my_address);
        for(uint j = 0; j < deFitasy_entries.length; j++) {
            uint current_points = get_points_defitasy_entrants(deFitasy_entries[0].players);
            if (current_points == max_points) {
                best_players.push(deFitasy_entries[i].my_address);
            } else if(current_points > max_points){
                max_points = current_points;
                delete best_players;
                best_players.push(deFitasy_entries[i].my_address);
            }
        }
        pay_winners();
    }
    // cron will open for 23 hours
    // close one hour before the game starts
    // send winnings 5 hours later
    
    function pay_winners() public payable {
        uint256 payment = address(this).balance / deFitasy_entries.length;
        for(uint i =0; i< deFitasy_entries.length; i++){
            deFitasy_entries[i].my_address.transfer(payment);
        }
    }
    
    function get_points_defitasy_entrants(uint256[5] memory players) public view returns(uint256){
        uint256 points = 0;
        for(uint256 i=0; i< NBA_Players.length; i++){
            points = points;
        }
    }
    
    function get_points_nba_players(uint256 id) public view returns(uint256){
        return 1; 
    }


    function close_entry() public onlyChainlinkAggregator{
        open = false;
    }
    
    function open_entry() public onlyChainlinkAggregator{
        open = true;
    }
    
    modifier onlyChainlinkAggregator {
        // assert(msg.sender); // If it is incorrect here, it reverts.
        _;                                     // Otherwise, it continues.
    } 
    
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }
    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
    }
    
    function concate(string memory one, string memory two) internal view returns(string memory)
    {
        return string(abi.encodePacked(one,two));
    }
    
    function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
}
 
    
}
