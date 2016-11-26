//
// CircleMagic.pde
// @author Zack M Fleischman
// @description An animation of a bunch of circles gettin' all trippy.
//

// Dimensions of the Screen
// NOTE: If you change these here, make sure to change them in the `size` function in `setup`
//       because Processing requires a straight up number instead of a variable for dumb reasons.
int _screenWidth = 800;
int _screenHeight = 800;

//////////////////////////////
// Number of Circles
//////////////////////////////
int _circlesPerRow = 45;
int _circlesPerCol = 45;
int _rowStepSize = _screenWidth/_circlesPerRow;
int _colStepSize = _screenHeight/_circlesPerCol;
// This is the number of rows and columns we extend past the edge of our screen. 
// (Important if we're offsetting the circles and don't want blank spaces around the edges.)
int _numCirclesPastEdge = 5; 


//////////////////////////////
// Circle Colors
//////////////////////////////
// Speed at which we cycle the green and blue channels for the circles.
float _greenOffsetSpeed = 500.0;
float _blueOffsetSpeed = 350.0;
float _minColorBrightness = 65; // Minimum value for a color channel


//////////////////////////////
// Circle Sizes
//////////////////////////////
int _defaultCircleSize = 10;
float _maxSizeOffset = 4;
float _xSizeChangeDelay = 700.0; // Smaller === faster
float _ySizeChangeDelay = 530.0; // Smaller === faster
int _maxSquashAndStretchDifference = 5; // SquashSize - StretchSize >= _maxSquashAndStretchDifference


//////////////////////////////
// Circle Positions
//////////////////////////////
float _xPositionChangeDelay = 950.0;
float _yPositionChangeDelay = 800.0;
float _maxPositionOffset = 65.0;

//////////////////////////////
// Ripple Parameters 
//////////////////////////////
float _rippleSpeed = 4000.0; // Smaller === faster
float _rippleAmplitude = 5;
float _rippleFrequency = 0.011;


///////////////////////////////////////////////////
// Time variables
int _timeDelta;
int _timeLastFrame;
int _timeThisFrame;
int _timeSinceStarted;

// Constants
float TWO_PI = 3.14159*2.0;
///////////////////////////////////////////////////

// Project init
void setup() 
{ 
    // Setup screen size
    // NOTE: Change `_screenWidth` and `_screenHeight` to be equal to whatever you shove in `size`.
    size(800, 800); // Processing requires the inputs to be numbers instead of vars for whatever reason

    // FPS
    frameRate(30);

    // Initialize Time
    _timeLastFrame = millis();
    _timeThisFrame = _timeLastFrame;
    _timeDelta = 0;
    _timeSinceStarted = 0;
}

// Updates all the time variables, notably `_timeSinceStarted` and `timeDelta`
void updateTime()
{
    _timeLastFrame = _timeThisFrame;
    _timeThisFrame = millis();
    _timeDelta = _timeThisFrame - _timeLastFrame;
    _timeSinceStarted += _timeDelta;
}

// Render Loop
void draw() 
{ 
    background(0, 0, 50);
    updateTime();

    // Loop over each circle's x and y pixel position on the screen. (Creating a grid of circles)
    for (int i = _rowStepSize/2 - _rowStepSize*_numCirclesPastEdge; i < _screenWidth + _rowStepSize*_numCirclesPastEdge; i+=_rowStepSize) {
        for (int j = _colStepSize/2 - _colStepSize*_numCirclesPastEdge; j < _screenHeight + _colStepSize*_numCirclesPastEdge; j+=_colStepSize) {
            PVector circlePos = getCirclePosition(i, j);
            PVector circleSize = getCircleSize(circlePos); // This is a 2D PVector because the circle is really an ellipse with stretch and squash
            color circleColor = getCircleColor(circlePos, circleSize.x);
            drawCircle(circlePos, circleSize, circleColor);
        }
    }
}

void drawCircle(PVector pos, PVector size, color c)
{
    fill(c);
    ellipse(pos.x, pos.y, size.x, size.y);
}

// Given the x,y pixel position on the screen, return a potentially offset position.
// This algorithm offsets each circle according to both a sin and cos wave with different frequencies.
PVector getCirclePosition(int x, int y)
{
    float xPerc = (float)x / _screenWidth;
    float yPerc = (float)y / _screenHeight;
    float radiansForWidth = (xPerc * TWO_PI) + (_timeSinceStarted / _xPositionChangeDelay);
    float radiansForHeight = (yPerc * TWO_PI) + (_timeSinceStarted / _yPositionChangeDelay);

    // Sin offset
    float xOffset = sin(radiansForWidth) * _maxPositionOffset;
    float yOffset = sin(radiansForHeight) * _maxPositionOffset;

    // Cos offset
    final int maxCosOffset = 5;
    float xOffset2 = cos(xPerc * TWO_PI) * maxCosOffset;
    float yOffset2 = cos(yPerc * TWO_PI) * maxCosOffset;

    return new PVector(x+xOffset+xOffset2, y+yOffset+yOffset2);
}

// Returns how big each circle should be based on it's position on the screen.
// This works by starting at a default size, adding a squash and stretch element,
// and then adding size based off the height of ripples that are going across the screen.
PVector getCircleSize(PVector circlePos)
{ 
    // Starts at a default size
    PVector circleSize = new PVector(_defaultCircleSize, _defaultCircleSize);

    // Deform the circle by stretching and squashing stretch and squash
    PVector squashAndStretchSizes = getSquashAndStretchSize(circlePos);
    circleSize.add(squashAndStretchSizes);

    // Get the ripple height from each of the 2 ripples.
    final float c = 350; // Distance each ripple is from center the center on X axis.
    float rightRippleHeight = getRippleHeight(circlePos, new PVector((_screenWidth/2) + c, _screenHeight/2), 0);
    float leftRippleHeight  = getRippleHeight(circlePos, new PVector((_screenWidth/2) - c, _screenHeight/2), 3.14);
    circleSize.add(new PVector(rightRippleHeight, rightRippleHeight));
    circleSize.add(new PVector(leftRippleHeight, leftRippleHeight));

    return circleSize;
}

// Return a circle's color as a function of it's position and size
// 
// For 2 color channels, this creates a color value that starts at the minimum brightness, 
// fades to the maximum halfway down the screen, and then fades back to the minimum at the bottom.
// (Then the whole thing shifts over time modulo the screen height and width according to the x and y offsets)
//
// For the third color channel, it's just a simple function of the color size.
color getCircleColor(PVector pos, float circleSize)
{
    // Get an (x,y) position that moves over time.
    float xOffset = (_timeSinceStarted / 1000.0) * _greenOffsetSpeed;
    float yOffset = (_timeSinceStarted / 1000.0) * _blueOffsetSpeed;
    float x = (pos.x + xOffset) % _screenWidth;
    float y = (pos.y + yOffset) % _screenHeight;

    // Calculate Green Channel 
    float green = (x/_screenWidth)*2.0;
    if (green > 1.0) green = 2.0 - green;
    green *= (255 - _minColorBrightness);
    green %= (255 - _minColorBrightness);
    green += _minColorBrightness;

    // Calculate Blue Channel
    float blue = (y/_screenHeight)*2.0;
    if (blue > 1.0) blue = 2.0 - blue;
    blue *= (255 - _minColorBrightness);
    blue %= (255 - _minColorBrightness);
    blue += _minColorBrightness;

    // Red channel is just a function of circle size and separate from the rest.
    float red = 255 - circleSize*10;

    return color(red, green, blue); 
}

// Given the position of a point on the screen, the center position of a ripple, and it's starting phase,
// this will output the height of the ripple at that point.
float getRippleHeight(PVector pos, PVector center, float startingPhase) {
    // Wave Constants
    float A = _rippleAmplitude;
    float f = _rippleFrequency;
    float p = startingPhase - (_timeSinceStarted / _rippleSpeed) * TWO_PI; // phase

    // Find distance from the ripple center to the point `pos`
    float xCenter = center.x - pos.x;
    float yCenter = center.y - pos.y;
    float t = sqrt(xCenter*xCenter + yCenter*yCenter);

    // get sizeOffset from wave shape
    // Equation of a wave: f(t) = A*sin(2*PI*f*t + p) 
    //      A = Amplitude, f = Frequency, t = Time, p = Phase
    float rippleHeight = A*sin(TWO_PI*f*t + p);

    return rippleHeight;
}

// The circle's each deform, getting squashed and stretched over time on the x and y axis respectively.
PVector getSquashAndStretchSize(PVector circlePos) {
    // Change the squash and stretch of the circle each according to a sin wave of different frequencies.
    float radiansForSquash  = (((float)circlePos.x / _screenWidth) * TWO_PI) + (_timeSinceStarted / _xSizeChangeDelay);
    float radiansForStretch = (((float)circlePos.y / _screenHeight) * TWO_PI) + (_timeSinceStarted / _ySizeChangeDelay);
    float squashSize = sin(radiansForSquash) * _maxSizeOffset;
    float stretchSize = sin(radiansForStretch) * _maxSizeOffset;

    // Enforce that the difference between the squash and stretch isn't too big so the 
    // circles aren't too deformed.
    if (squashSize - stretchSize > _maxSquashAndStretchDifference) {
        stretchSize = squashSize - _maxSquashAndStretchDifference;
    }
    if (stretchSize - squashSize > _maxSquashAndStretchDifference) {
        squashSize = stretchSize - _maxSquashAndStretchDifference;
    }

    return new PVector(squashSize, stretchSize);
}
