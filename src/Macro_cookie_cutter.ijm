// declare some variables 
// this allow you to get the last selected value
var sliceNumber = 10;
var wallThickness =10;
var userChoice = "Draw";
var enlargeBottom = true ;

macro "Cookie Cutter Paramerters[F1]"{
// here we create a dialog window to retrieve information from user
Dialog.create("Cookie Cutter");
Dialog.addNumber("Number of slice", sliceNumber);
Dialog.addNumber("Wall thickness",wallThickness);
Dialog.addString("Draw an image or use one (Draw or leave empty )",userChoice);
Dialog.addCheckbox("Enlarge one side to ease handle",enlargeBottom) ;
Dialog.show() ;

sliceNumber = Dialog.getNumber();
wallThickness = Dialog.getNumber();
userChoice = Dialog.getString();
enlargeBottom = Dialog.getCheckbox() ;

return ; 
}

macro "Cookie Cutter [F2]"{
// set fore/background value
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);

if (userChoice == "Draw"){
	//create an image
	newImage("draw", "8-bit black", 256, 256, 1);
	// select the freehand tool and wait for User to draw something
	setTool("freehand");
	waitForUser("Draw something please \nThus Press 'OK'");
	
}else{ // user want to use the current image 
	if( nImages == 0 ) {
		// error message if there is no image
		showMessage("no image open");
		return	;
	} else {
		//be sure to have the entire image selected and covert it to 8 bit (easier)
		run("Select All");
		run("8-bit");
		getDimensions(widthImage, heightImage, channelsImage, slicesImage, framesImage);
		// use custom function to define if the image has a dark or bright background
		// the function assumes that the background is the more important population of pixel
		bkgrd = isDarkBackground(); 
		//use a threshold to create a election
		setAutoThreshold("IsoData "+bkgrd);
		run("Create Selection");
		resetThreshold();
		//create a new iamge iwth same dimension and restore the selection
		newImage("draw", "8-bit black", widthImage, heightImage, 1);
		run("Restore Selection");
		
	}
}

// the ROI drawn by the user , or detected on the image
// is enlarge and filled 
// before being shrinken and cleared
run("Enlarge...", "enlarge="+wallThickness);
run("Fill", "slice");
run("Enlarge...", "enlarge=-"+wallThickness);
run("Clear", "slice");

// make sure to select all, and duplicate the image to the required number of Slice
run("Select All");
for (i = 0 ; i < sliceNumber ; i++){
    run("Duplicate...", " ");
}
selectImage(nImages);

// and making it a stack
run("Images to Stack", "name=draw title=[draw] use");

// it's possible to enlarge the bottom to ease the handling of the cookie cutter
if(enlargeBottom){
	bottomSlices = round(sliceNumber/5);
	for (i = 1 ; i <= bottomSlices ; i++){
	   Stack.setSlice(i);
	   run("Options...", "iterations=2 count=1 black do=Dilate slice");
	}
}

//propose to save as obj
run("Wavefront .OBJ ...");
//Final message
showMessage("Done");

}

// the function assumes that the background is the more important population of pixel
// get the histogram of the image, look for the bigger bin of the histogram
// calculate if it's closer to the in or the max, respectively dark or bright image		
function isDarkBackground (){
		getStatistics(areaImage, meanImage, minImage, maxImage, stdImage, histogramImage);
		// rank the histogram value
		rankPosArr = Array.rankPositions(histogramImage); 
		// the last index is the highest value
		biggerBinIndex =  rankPosArr[lengthOf(rankPosArr)-1]; 
		// measure the distance between the max and the bigger bin
		dMaxtobigBin = abs(maxImage-biggerBinIndex); 
		// same with the min
		dMintobigBin = abs(minImage-biggerBinIndex); 
		// compare if the bigger bin is closer to the min or the max, 
		// define dark or white background
		if ( dMaxtobigBin >= dMintobigBin ){ 
			return "dark";
			//print("black background");
		} else  {//white background
			return "";
			//print("white background");
		}
}
