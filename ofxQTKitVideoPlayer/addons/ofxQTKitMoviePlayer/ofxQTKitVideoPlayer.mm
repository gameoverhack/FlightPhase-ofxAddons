/*
 *  ofxQTKitMoviePlayer example
 *
 * Created by James George, http://www.jamesgeorge.org
 * over a long period of time for a few different projects in collaboration with
 * FlightPhase http://www.flightphase.com 
 * and the rockwell group lab http://lab.rockwellgroup.com
 *
 **********************************************************
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * ----------------------
 * 
 * ofxQTKitVideoPlayer provides QTKit/CoreVideo accelerated movie playback
 * for openFrameworks on OS X
 * 
 * This class replaces almost all of the functionality of ofVideoPlayer on OS X
 * and uses the modern QTKit and CoreVideo libraries for playback
 *
 * Special Thanks to Marek Bereza for his initial QTKitVideoTexture
 * http://www.mrkbrz.com/
 *
 * Thanks to Anton Marini for help wrangling buffer contexts
 * http://vade.info/ 
 */

#include "ofxQTKitVideoPlayer.h"

ofxQTKitVideoPlayer::ofxQTKitVideoPlayer()
{
	moviePlayer = NULL;
	moviePixels = NULL;
	bNewFrame = false;
	duration = 0;
	nFrames = 0;
}


ofxQTKitVideoPlayer::~ofxQTKitVideoPlayer()
{
	close();	
}

bool ofxQTKitVideoPlayer::loadMovie(string movieFilePath, int mode)
{
	if(mode < 0 || mode > 2){
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoPlayer -- Error, invalid mode specified for");
		return false;
	}
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if(moviePlayer != NULL){
		close();
	}
	
	bool useTexture = (mode == OFXQTVIDEOPLAYER_MODE_TEXTURE_ONLY || OFXQTVIDEOPLAYER_MODE_PIXELS_AND_TEXTURE);
	bool usePixels  = (mode == OFXQTVIDEOPLAYER_MODE_PIXELS_ONLY  || OFXQTVIDEOPLAYER_MODE_PIXELS_AND_TEXTURE);
	
	moviePlayer = [[QTKitMovieRenderer alloc] init];
	
	movieFilePath = ofToDataPath(movieFilePath, false);
	BOOL success = [moviePlayer loadMovie:[NSString stringWithCString:movieFilePath.c_str() encoding:NSUTF8StringEncoding] 
							 allowTexture:useTexture 
							  allowPixels:usePixels];

	if(success){
		duration = moviePlayer.duration;
		nFrames = moviePlayer.frameCount;
		width = moviePlayer.movieSize.width;
		height = moviePlayer.movieSize.height;
	}
	else {
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoPlayer -- Loading file " + movieFilePath + " failed");
		[moviePlayer release];
		moviePlayer = NULL;
	}
	
	[pool release];
	
	return success;
}

void ofxQTKitVideoPlayer::closeMovie()
{
	close();
}

bool ofxQTKitVideoPlayer::isLoaded()
{
	return moviePlayer != NULL;
}

void ofxQTKitVideoPlayer::close()
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if(moviePlayer != NULL){
		[moviePlayer release];
		moviePlayer = NULL;
	}
	
	if(moviePixels != NULL){
		delete moviePixels;
		moviePixels = NULL;
	}
	
	duration = 0;
	nFrames = 0;

	[pool release];	
}

void ofxQTKitVideoPlayer::pause()
{
	setSpeed(0);
}

bool ofxQTKitVideoPlayer::isPaused()
{
	return getSpeed() == 0.0;
}

void ofxQTKitVideoPlayer::setSpeed(float rate)
{
	if(moviePlayer == NULL) return;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[moviePlayer setRate:rate];

	[pool release];	
}

void ofxQTKitVideoPlayer::play()
{	
	if(moviePlayer == NULL) return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[moviePlayer setRate: 1.0];
	
	[pool release];
}

void ofxQTKitVideoPlayer::idleMovie()
{
	update();
}

bool ofxQTKitVideoPlayer::update()
{
	if(moviePlayer == NULL) return false;

	bNewFrame = [moviePlayer update];
	if (bNewFrame) {
		bHavePixelsChanged = true;
	}
}

bool ofxQTKitVideoPlayer::isFrameNew()
{
	return bNewFrame;
}
		
void ofxQTKitVideoPlayer::bind()
{
	if(moviePlayer == NULL || !moviePlayer.useTexture) return;
	
	[moviePlayer bindTexture];	
}

void ofxQTKitVideoPlayer::unbind()
{
	if(moviePlayer == NULL || !moviePlayer.useTexture) return;
	
	[moviePlayer unbindTexture];
}

void ofxQTKitVideoPlayer::draw(float x, float y)
{
	if(moviePlayer == NULL || !moviePlayer.useTexture) return;
	
	draw(x,y, moviePlayer.movieSize.width, moviePlayer.movieSize.height);
}

void ofxQTKitVideoPlayer::draw(float x, float y, float w, float h)
{
	if(moviePlayer == NULL || !moviePlayer.useTexture) return;
	
	[moviePlayer draw:NSMakeRect(x, y, w, h)];
}

unsigned char* ofxQTKitVideoPlayer::getPixels()
{
	if(moviePlayer == NULL || !moviePlayer.usePixels) {
		return NULL;
	}
		
	if(moviePixels == NULL){
		moviePixels = new unsigned char[int(moviePlayer.movieSize.width) * int(moviePlayer.movieSize.height) * 4];
	}
		
	//don't get the pixels every frame if it hasn't updated
	if(bHavePixelsChanged){
		[moviePlayer pixels:moviePixels];
		bHavePixelsChanged = false;
	}
	
	return moviePixels;
}

void ofxQTKitVideoPlayer::setPosition(float pct)
{
	if(moviePlayer == NULL) return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	moviePlayer.position = pct;
	
	[pool release];
}

void ofxQTKitVideoPlayer::setVolume(int volume)
{
	if(moviePlayer == NULL) return;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	moviePlayer.volume = volume;
	
	[pool release];
}

void ofxQTKitVideoPlayer::setFrame(int frame)
{
	if(moviePlayer == NULL) return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	moviePlayer.frame = frame % moviePlayer.frameCount;
	
	[pool release];
	
}

int ofxQTKitVideoPlayer::getCurrentFrame()
{
	if(moviePlayer == NULL) return 0;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	int currentFrame = moviePlayer.frame;
	
	[pool release];	
	
	return currentFrame;	
}

int ofxQTKitVideoPlayer::getTotalNumFrames()
{
	return nFrames;
}

void ofxQTKitVideoPlayer::setLoopState(bool loops)
{
	if(moviePlayer == NULL) return;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	moviePlayer.loops = loops;
	
	[pool release];
}

void ofxQTKitVideoPlayer::setLoopState(int ofLoopState)
{
	if(ofLoopState == OF_LOOP_NONE){
		setLoopState(false);
	}
	else if(ofLoopState == OF_LOOP_NORMAL){
		setLoopState(true);
	}
	
	//TODO support OF_LOOP_PALINDROME
}

bool ofxQTKitVideoPlayer::getMovieLoopState()
{
	if(moviePlayer == NULL) return NO;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	bool loops = moviePlayer.loops;
	
	[pool release];
	
	return loops;
}

float ofxQTKitVideoPlayer::getSpeed()
{
	if(moviePlayer == NULL) return 0;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	float rate = moviePlayer.rate;
	
	[pool release];
	
	return rate;
}

float ofxQTKitVideoPlayer::getDuration()
{
	return duration;
}

float ofxQTKitVideoPlayer::getPositionInSeconds()
{
	return getPosition() * duration;
}

float ofxQTKitVideoPlayer::getPosition()
{
	if(moviePlayer == NULL) return 0;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	float pos = moviePlayer.position;
	
	[pool release];
	
	return pos;
}

bool ofxQTKitVideoPlayer::getIsMovieDone()
{
	if(moviePlayer == NULL) return false;
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];	

	bool isDone = moviePlayer.isFinished;
	
	[pool release];
	
	return isDone;
}

int ofxQTKitVideoPlayer::getWidth()
{
	return moviePlayer.movieSize.width;
}

int ofxQTKitVideoPlayer::getHeight()
{
	return moviePlayer.movieSize.height;
}

