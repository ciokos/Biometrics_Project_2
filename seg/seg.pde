//images for different stages of the algorithm
PImage original;
PImage equalized;
PImage gray;
PImage tresholded;
PImage current;
PImage cut;

//variables for equalization
int[] reds;
int[] greens;
int[] blues;
float[] look_reds;
float[] look_greens;
float[] look_blues;
float maxr, minr, maxg, ming, maxb, minb;

//a button
Button button;

//variables for iris segmentation
int low = 60;
int high = 70;
int chosen_x = -1;
int chosen_y = -1;
int chosen_r = -1;
int chosen_r2 = -1;

void setup() {
  //create window
  size(500, 387);
  background(30);
  
  //initialize variables
  button = new Button(width - 110, height - 70, 80, 40, "Save");
  reds = new int[256];
  greens = new int[256];
  blues = new int[256];
  look_reds = new float[256];
  look_greens = new float[256];
  look_blues = new float[256];
  
  //load color eye image
  original = loadImage("eye0.jpg");
  
  //equalize image
  process(original);
  calculateLookUp(original);
  equalized = equalize(original);
  
  //convert to grayscale
  gray = toGray(equalized);
  
  //treshold
  tresholded = threshold(gray, 10);
  //image(tresholded, 0, 0, tresholded.width, tresholded.height);


  //find pupil
  find_pupil(tresholded);
  
  //find iris
  find_iris(gray, chosen_x, chosen_y, chosen_r);
  
  //cut photo
  cut = cut(original);
  
  //display it
  background(255); //<>//
  image(cut, 0, 0, cut.width, cut.height);
  println(chosen_r, chosen_r2);
}

//loop refreshing the button
void draw() {
  button.update();
  button.show();
}

//event handler also for button
void mousePressed() {
  current = cut;
  button.update();
}

//cutting iris from original image
PImage cut(PImage img) {
  background(255);
  stroke(0);
  fill(0);
  ellipse(chosen_x, chosen_y, chosen_r2, chosen_r2);
  stroke(255);
  fill(255);
  ellipse(chosen_x, chosen_y, chosen_r, chosen_r);
  PImage ret = get(0,0,img.width, img.height);
  background(255);
  loadPixels();
  for(int i = 0; i < img.pixels.length; i++) {
    if(red(ret.pixels[i]) < 126) {
      ret.pixels[i] = img.pixels[i];
    } else {
      ret.pixels[i] = color(255);
    }
  }
  return ret;
} //<>//

//calculate average color on circumference of a circle
float circle_average(PImage img, int x, int y, int size) {
  //input:
  //img - image from which we take the circle
  //x - x position of the center of the circle
  //y - y position of the center of the circle
  //size - radius of the circle
  //output:
  float ret = 0; //average
  //variable to count pixels on the circumference
  int circle = 0;
  //calculate starting positions
  int startx = x-size;
  int starty = y-size;
  //loop through window
  for(int i = 0; i < size*2+1; i++) {
    for(int j = 0; j < size*2+1; j++) {
       //move in the window
       int col = j + startx;
       int row = i + starty;
       //check if in image
       if(col < 0 || col > img.width-1 || row < 0 || row > img.height-1)
         continue;
       //check if on circumference
       if(floor(sqrt((col-x)*(col-x)+(row-y)*(row-y))) != size)
         continue;
       //increse number if added pixels
       circle++;
       //take color from the given pixel
       color c = img.pixels[row*img.width+col];
       //take [0, 255] grayness value from the pixel
       float grayness = red(c);
       //sum
       ret += grayness;
    }
  }
  //return average
  return ret/float(circle);
}

//find x-y position of the pupil and radius
void find_pupil(PImage img) {
  //in this variable I save the biggest difference
  float record = -1;
  //loop through every pixel
  for(int i = high; i < img.height - high; i++) {
    for(int j = high; j < img.width - high; j++) {
      //old average
      float old = -1;
      //difference between new and old value
      float difference = 0;
      //loop through every radius
      for(int s = high; s >= low; s--) {
        //calculate new average
        float val = circle_average(img, j, i, s);
        //I need to take care of the first check
        if(old<0)
        old = val;
        else {
          //calculate the difference
          difference = abs(old-val);
          //new average will now become old
          old = val;
          //check if this is the biggest difference yet
          if(difference > record) {
            //set record
            record = difference;
            //set coordinates and radius
            chosen_x = j;
            chosen_y = i;
            chosen_r = s*2+1;
          }  
        }     
      }      
    }
  }
}

//find radius of iris
void find_iris(PImage img, int x, int y, int r) {
  //the biggest difference
  float most_difference = 0;
  //save the previous average
  float old = -1;
  //loop through different radii,
  //start little further from the pupil
  for(int i = r+4; i < width/2-10; i++) {
    //calculate new average
    float avg = circle_average(img, x, y, i);
    //check if first difference
    if(old < 0) {
      old = avg;
    } else {
      //calculate difference
      float difference = abs(avg - old);
      //new average will now become old
      old = avg;
      //check if this is the biggest difference yet
      if(difference > most_difference) {
        //set record
        most_difference = difference;
        //set radius
        chosen_r2 = i*2+1;
      }
    }
  }
}

//convert image to grayscale
PImage toGray(PImage img) {
  //create new image with height and width of the original image
  PImage gray = createImage(img.width, img.height, RGB);
  //begin work on pixel level
  loadPixels();
  //loop through every pixel
  for (int i=0; i<img.pixels.length; i++) {
    //take color of the original pixel
    color c = img.pixels[i];
    //take average of red, green and blue channels
    float avg = (red(c) + green(c) + blue(c))/3;
    //set color of the new pixel
    gray.pixels[i] = color(avg, avg, avg);
  }
  //end work on pixels
  updatePixels();
  //return the result
  return gray;
}

//apply treshold
PImage threshold(PImage img, float T) {
  //create new image with height and width of the original image
  PImage thres = createImage(img.width, img.height, RGB);
  //begin work on pixel level
  loadPixels();
  //loop through every pixel
  for (int i=0; i<img.pixels.length; i++) {
    //take color of the original pixel
    color c = img.pixels[i];
    //take average of red, green and blue channels
    float avg = (red(c) + green(c) + blue(c))/3;
    //compare it with T and set to white or black
    if(avg<T) {
     avg = 0;
    } else {
     avg = 255; 
    }
    //set color of the new pixel
    thres.pixels[i] =  color(avg, avg, avg);
  }
  //end work on pixels
  updatePixels();
  //return the result
  return thres;
}

//functions for equalization
void process(PImage img) {
  img.loadPixels();
  for(int i = 0; i < img.pixels.length; i++) {
    color c = img.pixels[i];
    reds[(int)red(c)]++;
    greens[(int)green(c)]++;
    blues[(int)blue(c)]++;
  }
}

void calculateLookUp(PImage img) {
  //The denominator for Di's
  float den = img.width * img.height;
  //D zeros for each channel
  float D0r = reds[0]/den;
  float D0g = greens[0]/den;
  float D0b = blues[0]/den;
  //variables to cumulate probabilities
  float sumr = 0;
  float sumg = 0;
  float sumb = 0;
  //Di's for each channel
  float Dir, Dig, Dib;
  //go through every possible value
  for(int i = 0; i < 256; i++) {
    //accumulate data from histograms
    sumr += reds[i];
    sumg += greens[i];
    sumb += blues[i];
    //calculate new probs
    Dir = sumr/den;
    Dig = sumg/den;
    Dib = sumb/den;
    //use formula to fill look up tables
    look_reds[i] = (Dir-D0r)*255/(1-D0r);
    look_greens[i] = (Dig-D0g)*255/(1-D0g);
    look_blues[i] = (Dib-D0b)*255/(1-D0b);
  }
}

PImage equalize(PImage img) {
  //create new image with height and width of the original image
  PImage eq = createImage(img.width, img.height, RGB);
  //begin work on pixel level
  loadPixels();
  //loop through every pixel
  for (int i=0; i<img.pixels.length; i++) {
    //take color of the original pixel
    color c = img.pixels[i];
    //find every channel value using look up tables
    float r = look_reds[(int)red(c)];
    float g = look_greens[(int)green(c)];
    float b = look_blues[(int)blue(c)];
    //set color of the new pixel
    eq.pixels[i] =  color(r, g, b);
  }
  //end work on pixels
  updatePixels();
  //return the result
  return eq;
}
