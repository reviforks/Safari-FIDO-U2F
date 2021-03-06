//
//  SafariExtensionHandler.swift
//  Safari FIDO U2F Extension
//
//  Created by Yikai Zhao on 10/13/16.
//
//  ----------------------------------------------------------------
//  Copyright (c) 2016-present, Yikai Zhao, Sam Deane, et al.
//
//  This source code is licensed under the MIT license found in the
//  LICENSE file in the root directory of this source tree.
//  ----------------------------------------------------------------

import SafariServices

let U2FSignMessage = "U2FSign"
let U2FRegisterMessage = "U2FRegister"
let U2FResponseMessage = "U2FResponse"

let U2F_V2 = "U2F_V2"
let U2F_NODEVICE_RETRY_COUNT = 10




class SafariExtensionHandler: SFSafariExtensionHandler {
    
    func sendResponse(page: SFSafariPage, response: String) {
        let userinfo = [ "result" : response]
        page.dispatchMessageToScript(withName: U2FResponseMessage, userInfo: userinfo)
    }

    func sendError(page: SFSafariPage, error: U2FError) {
        var userinfo: [String: Any] = [:]
        switch error {
        case U2FError.unknown(let pos):
            userinfo["error"] = "Unknown Error in \(pos)"
        case U2FError.error(let errcode, let pos):
            let errmsg = String.init(cString: u2fh_strerror(errcode.rawValue))
            userinfo["error"] = "Error in \(pos): \(errmsg)"
        case U2FError.badRequest():
            userinfo["error"] = "Bad Request"
        }
        page.dispatchMessageToScript(withName: U2FResponseMessage, userInfo: userinfo)
    }


    /**
     Process a message from the content script.
     
     We construct a request based on the name of the message.
     We then make a new device
     We attempt to construct
     */

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").

        page.getPropertiesWithCompletionHandler { properties in
            do {
                let request = try U2FSignRequest.ParseRequest(name: messageName, info:userInfo, properties:properties)
                let device = try U2FDevice()
                let response = try request.Perform(device: device)
                self.sendResponse(page: page, response: response)
            } catch let error as U2FError {
                self.sendError(page: page, error: error)
            } catch {
                self.sendError(page: page, error: U2FError.unknown(in: "messageReceived"))
            }
        }
    }

}
