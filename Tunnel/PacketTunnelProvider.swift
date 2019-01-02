//
//  PacketTunnelProvider.swift
//  Tunnel
//
//  Created by lichao on 2019/1/2.
//  Copyright © 2019 charles. All rights reserved.
//

import NetworkExtension

 

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let ssprovider = SSPacketTunnelProvider();
    
    var dominString = ""
    
    
    override init() {
        super.init();
        ssprovider.delegate = self;
        ssprovider.defaultPath = defaultPath;
        ssprovider.packetFlow = packetFlow;
    }
    
    
    //
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        ssprovider.startTunnel(options: options, completionHandler: completionHandler)
        return;
        
        guard let option = options else {
            super.startTunnel(completionHandler: completionHandler)
            return
        }
        
        guard let domin = option["domin"] else {
            super.startTunnel(completionHandler: completionHandler)
            return
        }
        self.dominString = domin as! String
        
        guard let type = option["type"] else {
            super.startTunnel(completionHandler: completionHandler)
            return
        }
        if type as! String == "ss"{
            ssprovider.startTunnel(options: options, completionHandler: completionHandler)
        }else{
            super.startTunnel(completionHandler: completionHandler)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.ssprovider.stopTunnel(with: reason, completionHandler: completionHandler)
            super.stopTunnel(with: reason, completionHandler: completionHandler)
        }
    }
    
    
    
}

extension PacketTunnelProvider: SSPacketTunnelProviderProtocol{
    //MARK: - PacketTunnelProviderProtocol
    func customCancelTunnelWithError(_ error: Error?) {
        cancelTunnelWithError(error);
    }
    
    func customSetTunnelNetworkSettings(_ tunnelNetworkSettings: NETunnelNetworkSettings?, completionHandler: ((Error?) -> Void)? = nil) {
        setTunnelNetworkSettings(tunnelNetworkSettings, completionHandler: completionHandler);
    }
}

