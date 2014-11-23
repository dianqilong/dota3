<?php
/**
 * 聊天逻辑，使用的协议是 文本+回车
 * 测试方法 运行
 * telnet ip 8480
 * 可以开启多个telnet窗口，窗口间可以互相聊天
 * 
 * websocket协议的聊天室见workerman-chat及workerman-todpole
 * 
 * @author walkor <walkor@workerman.net>
 */

use \Lib\Context;
use \Lib\Gateway;
use \Lib\StatisticClient;
use \Lib\Store;
use \Protocols\GatewayProtocol;
use Protocols\JsonProtocol;

use Module\MsgDefine;

class Event
{
    // 客户端消息监听者列表
    public static $m_msgListeners = array();
    
    // 进程启动
    public static function onStart(){
        static::addMsgListener(MsgDefine::REQUEST_JOIN_MATCH, array("Module\PvpManager","UpdatePlayer"));
    }

    /**
     * 当网关有客户端链接上来时触发，每个客户端只触发一次，如果不许要任何操作可以不实现此方法
     * 这里当客户端一连上来就给客户端发送输入名字的提示
     */
    public static function onGatewayConnect($client_id)
    {
        // 下发客户端ID
        Gateway::sendToCurrentClient(JsonProtocol::encode(array(MsgDefine::RESPOND_CLIENTID, $client_id)));
    }
    
    /**
     * 网关有消息时，判断消息是否完整
     */
    public static function onGatewayMessage($buffer)
    {
        return JsonProtocol::check($buffer);
    }
    
   /**
    * 有消息时触发该方法
    * @param int $client_id 发消息的client_id
    * @param string $message 消息
    * @return void
    */
   public static function onMessage($client_id, $message)
   {
       // 解析客户端消息       
        $msg = JsonProtocol::decode($message);
        print_r($msg);
        $listeners = static::$m_msgListeners[$msg[0]];
        if (!is_array($listeners)) {
            return;
        }
        
        // 分发消息
        foreach($listeners as $listener)
        {
            call_user_func_array($listener, array($msg));
        }
        
        return 0;

        return Gateway::sendToCurrentClient(JsonProtocol::encode($message_data));
        
        // **************如果没有$_SESSION['name']说明没有设置过用户名，进入设置用户名逻辑************
        if(empty($_SESSION['name']))
        {
            $_SESSION['name'] = JsonProtocol::decode($message);
            Gateway::sendToCurrentClient("chat room login success, your client_id is $client_id, name is {$_SESSION['name']}\r\nuse client_id:words send message to one user\r\nuse words send message to all\r\n");
             
            // 广播所有用户，xxx come
            return GateWay::sendToAll(JsonProtocol::encode("{$_SESSION['name']}[$client_id] come"));
        }
        
        // ********* 进入聊天逻辑 ****************
        // 判断是否是私聊
        $explode_array = explode(':', $message, 2);
        // 私聊数据格式 client_id:xxxxx
        if(count($explode_array) > 1)
        {
            $to_client_id = (int)$explode_array[0];
            GateWay::sendToClient($client_id, JsonProtocol::encode($_SESSION['name'] . "[$client_id] said said to [$to_client_id] :" . $explode_array[1]));
            return GateWay::sendToClient($to_client_id, JsonProtocol::encode($_SESSION['name'] . "[$client_id] said to You :" . $explode_array[1]));
        }
        // 群聊
        return GateWay::sendToAll(JsonProtocol::encode($_SESSION['name'] . "[$client_id] said :" . $message));
   }
   
   /**
    * 当用户断开连接时触发的方法
    * @param integer $client_id 断开连接的用户id
    * @return void
    */
   public static function onClose($client_id)
   {
       // 广播 xxx 退出了
       GateWay::sendToAll(JsonProtocol::encode("{$_SESSION['name']}[$client_id] logout"));
   }
   
   // 添加消息监听者
   public static function addMsgListener($msg_id, $listener){
       if (!array_key_exists($msg_id, static::$m_msgListeners)){
           static::$m_msgListeners[$msg_id] = array();
       }
       
       array_push(static::$m_msgListeners[$msg_id], $listener);
   }
}
