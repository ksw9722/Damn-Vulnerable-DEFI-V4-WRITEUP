pragma solidity =0.8.25;


interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AttackerModule {
   

    function tokenApprove(address _token, address _to) external{
        IERC20 token = IERC20(_token);
        uint256 balance = 10e18;
        token.approve(_to, balance);
    }

}