////////////////////////////////////////////////
///////SET FRAME SIZE BEFORE DOING ANYTHING/////
////////////////////////////////////////////////

import processing.video.*;

//////CONSTANTS//////
final boolean IMAGEMODE = false; //If just being used to process one image
final boolean DEBUG = false; //Turns on various things to help with debugging
final int MARGIN = 5; //The margin at the top and left of the screen
final int LINEHEIGHT = 12; //The line height between the lines of text
final int FINALBOLDPOINT = 80;
final int BOLDINCREASEAMOUNT = 1;
final color BACKGROUNDCOLOR = color(255);
final color TEXTCOLOR = color(0);
final String word = "and";

//////Globals//////
PImage theImage; //For use when you want only an image
Movie theMovie;
PImage theFrame;
PFont font; //The normal font i.e. the background
PFont bold; //The "bold" font i.e. wherever there is a darker area
PFont wordFont;
String[] fullText; //Array of every string in the loaded text with each line as a string
float boldPoint = 80; //Point at which pixel value is switched to bold //Less is darker //0 for fade-in
boolean runOnce = true; //Keeps track if the movie processing has run

void setup(){
  size(1080, 720);
  background(BACKGROUNDCOLOR); //White
  
  fullText = loadStrings("pAndP.txt"); 

  //////Movie//////
  if(!IMAGEMODE){
    theMovie = new Movie(this, "testMovie2.mov");
    theMovie.play();
    theMovie.pause();
    theMovie.frameRate(24);
    
  //////Image//////
  }else{
    theImage = loadImage("testMovieFrame.png");
    println("Textifying Image");
  }
  
  //////Fonts//////
  font = createFont("Helvetica", 12);
  bold = createFont("Helvetica-Bold", 12);
  wordFont = createFont("LeagueScriptThin-LeagueScript", 6);
  //bold = createFont("Avenir", 12);
  //bold = createFont("LeagueScriptThin-LeagueScript", 16);
  textFont(font);
}  

void draw(){

  if(IMAGEMODE){
    boldPoint = FINALBOLDPOINT; //For tweaking in tweak mode comment out and add number
    //Erase screen and redraw
    background(BACKGROUNDCOLOR); //White
    textify(theImage);
  }
  
  //Once the movie has ended, start processing
  //&& (theMovie.time() >= theMovie.duration()
  if(runOnce && !IMAGEMODE){
    runOnce = false;
    println("Textify movie with framerate: " + theMovie.frameRate);
    analyzeFrames(theMovie);
  }
}

//Called whenever a key is pressed
void keyPressed(){
  //println(key);
  if(key == ' '){
    save("screenshots/Screenshot " + year() + ":" + month() + ":" + day() + "--" + hour() + "-" + minute() + "-" + second() + ".png");
    println("Saved Screenshot");
  }
  println("width: " + width + " height: " + height);
}

void analyzeFrames(Movie mov){
  float frameDuration = 1.0 / mov.frameRate;
  float position;
  float diff;
  PImage currentFrame;
  println(mov.duration());
  println(mov.frameRate);
  for(int i=0; i < (mov.duration() * mov.frameRate); i++){
    mov.play();
    position = (i + 0.5) * frameDuration;
    // Taking into account border effects:
    diff = mov.duration() - position;
    if (diff < 0) {
      position += diff - 0.25 * frameDuration;
    }

    mov.jump(position);
    mov.pause();
    
    //Gradually increase (lesson) the bold point at the beginning of the video
    if(boldPoint <= FINALBOLDPOINT){
      boldPoint+=BOLDINCREASEAMOUNT;
    }
    
    
    //Clear the screen
    background(BACKGROUNDCOLOR);//white
    //Textify frame
    mov.read();
    currentFrame = mov.get();
    textify(currentFrame);
    //save frame
    println("Saving frame - " + nf(i, 6));
    save("frames/frame - " + nf(i, 6) + ".png");
  }
  println("Finished analyzing frames!");
}

void textify(PImage img){
  ///////DEBUG//////
 if(DEBUG){
  image(img, 0, 0, img.width, img.height);
 }
 ///////DEBUG//////  
 
  img.loadPixels();
  
  textSize(12);
  
  fill(TEXTCOLOR);
  
  float xPos = MARGIN;
  float yPos = MARGIN;
  float wordWidth = 0;
  String word = "";
  String currentLetter = "";
  float letterWidth = 0;
  boolean[] wordBoldness = new boolean[0];
  int newLineSpaceCounter = 0;
  
  //For every string in fullText
  for(int i = 0; i < fullText.length; i++) {
    
    //If beyond the window, no use doing everything
    if(yPos > height){
       break; 
    }
    
    fullText[i] = fullText[i].replace("\n"," ");
    fullText[i] = fullText[i]. replace("\r"," ");

    //For each letter on the line
    for(int j=0; j<fullText[i].length(); j++){
      
      currentLetter = fullText[i].substring(j, j+1);

      letterWidth = textWidth(currentLetter);
      boolean isBold = analyzePixels(img, xPos, yPos, letterWidth);

      //Add whether or not the letter is bold for printing to screen later
      wordBoldness = (boolean[])append(wordBoldness, isBold);
      
      //If the text is going to be bold, add the bold width, else just add the width
      if(isBold){
        textFont(bold);
        letterWidth= textWidth(currentLetter);
        textFont(font);
      }
      
      wordWidth += letterWidth;
      xPos += letterWidth;
      //Add letter to word
      word += currentLetter;
      
      ////////DEBUG/////////
      if(DEBUG){
        stroke(color(255, 0, 0));
        line(xPos, yPos, xPos, yPos+LINEHEIGHT); //Red line to show letter area
      }
      ////////DEBUG/////////
      
      //If the next letter is a space, check to see if it fits on this line
      //If not put on new line and re-analyze
      if(((j+1) < fullText[i].length() && fullText[i].substring(j+1, j+2).equals(" "))
      || j == (fullText[i].length() - 1)){
        if(xPos > width){
          xPos = MARGIN;
          yPos += LINEHEIGHT;
          //Restart for loop at word start (j - # of letters in word)
          j = (j - (word.length() - newLineSpaceCounter));
        }else{ //The word will fit on the line
          writeToScreen(word, (xPos - wordWidth), yPos, wordBoldness);
        }
        //Reset for next word
          word = "";
          wordWidth = 0;
          wordBoldness = new boolean[0];
          newLineSpaceCounter = 0;
      }
      
    }//End of each letter for
    
    //Add spaces between lines
    word += " ";
    wordBoldness = (boolean[])append(wordBoldness, false);
    letterWidth = textWidth(" ");
    wordWidth += letterWidth;
    xPos += letterWidth;
    newLineSpaceCounter++;
    
  }//End of each line for 
}

//Analyze the X and Y pixels from the beginning of xPos and yPos
//to the width of the letter. Return if bold based on average and boldness value global
boolean analyzePixels(PImage img, float xPos, float yPos, float letterWidth){
  
  //If beyond the window, no use doing everything
    if(yPos >= (height - LINEHEIGHT)){
       return false; 
    }
  
  float red = 0;
  float green = 0;
  float blue = 0;
  float avg = 0;
  float blockAvg = 0;
  int pixelCounter = 0; //Counts how many pixels
  float pixelPos = 0; //Keeps track of what index to read for the image's pixels
  
  for(float l=xPos ; l <= (xPos + letterWidth); l++){
    //From the top of the line to the bottom of the line
    for(float m=yPos; m <= (yPos+LINEHEIGHT); m++){
       //<>// //<>// //<>//
      pixelPos = (l + (m * width));
      red = red(img.pixels[(int)pixelPos]);
      green = green(img.pixels[(int)pixelPos]);
      blue = blue(img.pixels[(int)pixelPos]);
      avg = (red + green + blue)/3;
      //line(l,m,l,m);
      //Add the average to the average for the letter
      blockAvg += avg;
      pixelCounter++;
    }//End of y pixel for
  }//End of x pixel for
  
  //If the average pixel is less than the bold point (less is darker)
  return ((blockAvg/pixelCounter) < boldPoint);      
}


//Write text to screen at xPos, yPos using boldness array to define 
//if each letter is bold or not
void writeToScreen(String text, float xPos, float yPos, boolean[] boldness){
  //Reset yPos to bottom, not top
  yPos += LINEHEIGHT;
  //Remove the whitespace from the string and check if it's the word
  boolean isWord = trim(text).equalsIgnoreCase(word); //<>//
  
  //For each letter in word
  for(int i=0; i < text.length(); i++){
    if(boldness[i]){
      textFont(bold);
    }else if(isWord){
      textFont(wordFont);
    }
    text((text.substring(i, i+1)), xPos, yPos);
    
    //Add letter width to curser position
    xPos += textWidth(text.substring(i, i+1));
    
    //Put back to normal font as the default
    textFont(font);
  }
}