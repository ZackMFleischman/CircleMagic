int WIDTH = 800;
int HEIGHT = 800;

int _circlesPerRow = 45;
int _circlesPerCol = 45;
int _numCirclesPastEdge = 5;

float _redOffsetSpeed = 500.0;
float _blueOffsetSpeed = 350.0;

int _defaultCircleSize = 10;
float _maxSizeOffset = 4;

float _rippleDelay = 4000.0;
float _rippleAmplitude = 5;  // amplitude
float _rippleFrequency = 0.011; // frequency

float _xSizeChangeDelay = 700.0;
float _ySizeChangeDelay = 530.0;

float _xPositionChangeDelay = 950.0;
float _yPositionChangeDelay = 800.0;
float _maxPositionOffset = 65.0;

float minColorBrightness = 65;


/////
float TWO_PI = 3.14159*2.0;
int _timeDelta;
int _timeLastFrame;
int _timeThisFrame;
int _timeSinceStarted;
int _rowStepSize = WIDTH/_circlesPerRow;
int _colStepSize = HEIGHT/_circlesPerCol;
/////

void setup() 
{ 
  size(800, 800); // requires the inputs to be numbers instead of vars for whatever reason
  frameRate(30);

  // Initialize Time
  _timeLastFrame = millis();
  _timeThisFrame = _timeLastFrame;
  _timeDelta = 0;
  _timeSinceStarted = 0;
} 

void draw() 
{ 
  background(0, 0, 50);
  refreshTimeDelta();

  for (int i = _rowStepSize/2 - _rowStepSize*_numCirclesPastEdge; i < WIDTH + _rowStepSize*_numCirclesPastEdge; i+=_rowStepSize) {
    for (int j = _colStepSize/2 - _colStepSize*_numCirclesPastEdge; j < HEIGHT + _colStepSize*_numCirclesPastEdge; j+=_colStepSize) {
      PVector circlePos = getCirclePosition(i, j);
      PVector circleSize = getCircleSize(circlePos);
      color circleColor = getCircleColor(circlePos, circleSize.x);
      drawCircle(circlePos, circleSize, circleColor);
    }
  }
}

// Gets the number of milliseconds that have passed since the last frame and shoves it in _timeDelta
void refreshTimeDelta()
{
  _timeLastFrame = _timeThisFrame;
  _timeThisFrame = millis();
  _timeDelta = _timeThisFrame - _timeLastFrame;
  _timeSinceStarted += _timeDelta;
}

void drawCircle(PVector pos, PVector size, color c)
{
  fill(c);
  ellipse(pos.x, pos.y, size.x, size.y);
}

// Get position offset from grid position x,y (pixels)
PVector getCirclePosition(int x, int y)
{
  /*return new PVector(x, y);*/
  float xPerc = (float)x / WIDTH;
  float yPerc = (float)y / HEIGHT;
  float radiansForWidth = (xPerc * TWO_PI) + (_timeSinceStarted / _xPositionChangeDelay);
  float radiansForHeight = (yPerc * TWO_PI) + (_timeSinceStarted / _yPositionChangeDelay);

  float xOffset = sin(radiansForWidth) * _maxPositionOffset;
  float yOffset = sin(radiansForHeight) * _maxPositionOffset;
  
  float xOffset2 = cos(xPerc * TWO_PI) * 5;
  float yOffset2 = cos(yPerc * TWO_PI) * 5;

  return new PVector(x+xOffset+xOffset2, y+yOffset+yOffset2);
}

color getCircleColor(PVector pos, float circleSize)
{
  float xOffset = (_timeSinceStarted / 1000.0) * _redOffsetSpeed;
  float yOffset = (_timeSinceStarted / 1000.0) * _blueOffsetSpeed;
  float x = (pos.x + xOffset) % WIDTH;
  float y = (pos.y + yOffset) % HEIGHT;
  
  
  float red = (x/WIDTH)*2.0;
  if (red > 1.0) red = 2.0 - red;
  red *= (255 - minColorBrightness);
  
  float blue = (y/HEIGHT)*2.0;
  if (blue > 1.0) blue = 2.0 - blue;
  blue *= (255 - minColorBrightness);

  red %= (255 - minColorBrightness);
  blue %= (255 - minColorBrightness);
  red += minColorBrightness;
  blue += minColorBrightness;
  
  float green = 255 - circleSize*10;
  return color(green, red, blue); // Swapped red and green channels
}

float getRippleSize(PVector pos, PVector center, float startingPhase) {
    // Wave Constants
    float A = _rippleAmplitude; // amplitude
    float f = _rippleFrequency; // frequency
    float p = startingPhase - (_timeSinceStarted / _rippleDelay) * TWO_PI; // phase

    // get t from x, y
    float xCenter = center.x - pos.x;
    float yCenter = center.y - pos.y;
    float t = sqrt(xCenter*xCenter + yCenter*yCenter);

    // get sizeOffset from wave shape
    float sizeOffset = A*sin(TWO_PI*f*t + p);

    return sizeOffset;
}

PVector getCircleSize(PVector circlePos)
{ 
    float radiansForWidth = (((float)circlePos.x / WIDTH) * TWO_PI) + (_timeSinceStarted / _xSizeChangeDelay);
    float radiansForHeight = (((float)circlePos.y / HEIGHT) * TWO_PI) + (_timeSinceStarted / _ySizeChangeDelay);

    float xSizeOffset = sin(radiansForWidth) * _maxSizeOffset;
    float ySizeOffset = sin(radiansForHeight) * _maxSizeOffset;

    int maxDiff = 5;
    if (xSizeOffset - ySizeOffset > maxDiff) {
        ySizeOffset = xSizeOffset - maxDiff;
    }
    if (ySizeOffset - xSizeOffset > maxDiff) {
        xSizeOffset = ySizeOffset - maxDiff;
    }

    float c = 350;
    float rippleSize = getRippleSize(circlePos, new PVector((WIDTH/2) + c, HEIGHT/2), 0);
    rippleSize      += getRippleSize(circlePos, new PVector((WIDTH/2) - c, HEIGHT/2), 3.14);
    /*rippleSize      += getRippleSize(circlePos, new PVector(WIDTH/2, (HEIGHT/2 + c)), 0);*/
    /*rippleSize      += getRippleSize(circlePos, new PVector(WIDTH/2, (HEIGHT/2 - c)), 0);*/

    return new PVector(_defaultCircleSize + xSizeOffset + rippleSize, _defaultCircleSize + ySizeOffset + rippleSize);
}
