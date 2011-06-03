/**
 *  testApp.cpp
 *
 *	ofxQTKitveVideoGrabber example project
 *
 *  Created by James George ( http://www.jamesgeorge.org ) on 6/15/10.
 *  In collaboration with FlightPhase ( http://www.flightphase.com )
 *
 *  Copyright (c) 2010 
 *
 * Video & Audio sync'd recording + named device id's 
 * added by gameover [matt gingold] (c) 2011 http://gingold.com.au
 * with the support of hydra poesis http://hydrapoesis.net
 *
 *	This code is distributed under an MIT license you can use it
 *	for whatever you'd like, if you make improvements consider sharing
 *	them back
 */

#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){	 
	
	camWidth 		= CAM_WIDTH;	// try to grab at this size. 
	camHeight 		= CAM_HEIGHT;
	
	//ofSetLogLevel(OF_LOG_VERBOSE);
	
	vidGrabber.listVideoDevices();
	vidGrabber.listAudioDevices();
	
	vidGrabber.setVideoDeviceID("Built-in iSight");							// can set deviceID's by string
	vidGrabber.setAudioDeviceID("Built-in Microphone");
	
	vidGrabber.listVideoCodecs();
	vidGrabber.listAudioCodecs();
	
	vidGrabber.setVideoCodec("QTCompressionOptions240SizeH264Video");		// default is JPEG
	vidGrabber.setAudioCodec("QTCompressionOptionsVoiceQualityAACAudio");	// default is High Quality AAC
	
	vidGrabber.initGrabber(camWidth, camHeight, true);	// the third prop sets audio device init for recording
														// it can be omitted and will then defualt to false
	
	//vidGrabber.initGrabber();							// this overloaded version of initGrabber can be used
														// to create a recorder with no preview image or texture etc
														// it defualts to recording audio but you can pass false 
														// ie., initGrabber(false) if you wanna only record video
														// remember NOT to call update or draw!!!
	
	vidGrabber.initRecording();							// call this to init recording output 
														// see keyPressed below for start/stop commands
	
	
	videoInverted 	= new unsigned char[camWidth*camHeight*3];
	videoTexture.allocate(camWidth, camHeight, GL_RGB);
	
}

//--------------------------------------------------------------
void testApp::update(){
	
	ofBackground(100,100,100);
	
	vidGrabber.grabFrame();
	
	if (vidGrabber.isFrameNew()){
		int totalPixels = camWidth*camHeight*3;
		unsigned char * pixels = vidGrabber.getPixels();
		for (int i = 0; i < totalPixels; i++){
			videoInverted[i] = 255 - pixels[i];
		}
		videoTexture.loadData(videoInverted, camWidth,camHeight, GL_RGB);
	}

}

//--------------------------------------------------------------
void testApp::draw(){
	ofSetColor(0xffffff);
	vidGrabber.draw(0,0);
	videoTexture.draw(camWidth,0,camWidth,camHeight);
	
	ofSetColor(0x00ff00);
	
	string msg;
	msg += "Press the space bar to toggle recording!\n";
	msg += (string)(vidGrabber.isRecording() ? "RECORDING" : "NOT RECORDING");
	ofDrawBitmapString(msg, 20, ofGetHeight()-40);
}


//--------------------------------------------------------------
void testApp::keyPressed  (int key){ 
	switch (key) {
		case ' ':
			if (!vidGrabber.isRecording()) {
				vidGrabber.startRecording(ofToDataPath("output.mov")); // dumps to data folder
			} else vidGrabber.stopRecording();
			break;
		default:
			break;
	}
}


//--------------------------------------------------------------
void testApp::keyReleased(int key){ 
	
}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){
	
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){
	
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){
	
}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}
