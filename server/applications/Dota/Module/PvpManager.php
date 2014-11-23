<?php
namespace Module;
/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
class PvpManager {

    public static $m_match = array();

    public static function UpdatePlayer($msg) {
        $m_match[$msg[0]] = $msg[1];
    }

}
