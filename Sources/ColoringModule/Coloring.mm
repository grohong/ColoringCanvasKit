//
//  Coloring.mm
//
//
//  Created by Hong Seong Ho on 8/11/24.
//

#import "Coloring.h"
#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#endif
#import <opencv2/imgcodecs/ios.h>

@implementation Coloring

cv::Mat thresholdImage;
cv::Mat patternImage;
cv::Mat maskImage;
cv::Mat invertedMask;
cv::Mat strokeImage;
bool hasMask = false;
std::vector<cv::Point> points;

+(cv::Size) getMaskSize {
    cv::Size size = cv::Size(thresholdImage.size().width + 2, thresholdImage.size().height + 2);
    return size;
}

+(UIColor* _Nullable) getPixelColor:(nullable void *) data
                              width:(int)width
                             height:(int)height
                        bytesPerRow:(int)bytesPerRow
                              point:(CGPoint)point {
    cv::Mat source(height, width, CV_8UC4, data, bytesPerRow);
    cv::Point cvPoint = cv::Point(point.x, point.y);
    cv::Mat channels[4];
    cv::split(source, channels);
    int a = channels[3].at<uchar>(cvPoint.y, cvPoint.x);
    if (a != 255) {
        return NULL;
    } else {
        int r = channels[2].at<uchar>(cvPoint.y, cvPoint.x);
        int g = channels[1].at<uchar>(cvPoint.y, cvPoint.x);
        int b = channels[0].at<uchar>(cvPoint.y, cvPoint.x);
        return [UIColor colorWithRed:(CGFloat(r) / 255) green:(CGFloat(g) / 255) blue:(CGFloat(b) / 255) alpha:1];
    }
}

+(NSMutableArray* _Nonnull) setImage:(nullable void *) data
                               width:(int)width
                              height:(int)height
                         bytesPerRow:(int)bytesPerRow
                           threshold:(int)threshold {
    cv::Mat source(height, width, CV_8UC4, data, bytesPerRow);
    cv::Mat gray;
    cv::cvtColor(source, gray, cv::COLOR_RGBA2GRAY);
    cv::threshold(gray, thresholdImage, threshold, 255, cv::THRESH_BINARY);
    cv::Mat inverted;
    cv::bitwise_not(thresholdImage, inverted);
    cv::Mat channels[4];
    cv::split(source, channels);
    channels[3] = inverted;
    cv::Mat dst;
    cv::merge(channels, 4, dst);
    cv::Mat background = cv::Mat(source.size(), CV_8UC3, cv::Scalar(255, 255, 255));
    cv::cvtColor(background, background, cv::COLOR_RGB2RGBA);
    auto bg = MatToUIImage(background);
    auto fg = MatToUIImage(dst);
    NSMutableArray *myArray = [[NSMutableArray alloc] init];
    [myArray addObject: bg];
    [myArray addObject: fg];
    return myArray;
}

+(void) setPattern:(nullable void *) data
             width:(int)width
            height:(int)height
       bytesPerRow:(int)bytesPerRow {
    cv::Mat source(height, width, CV_8UC4, data, bytesPerRow);
    cv::cvtColor(source, source, cv::COLOR_BGRA2RGBA);
    cv::Size size = [self getMaskSize];
    int xRepeat = size.width / source.size().width;
    if (thresholdImage.size().width % source.size().width != 0) {
        xRepeat += 1;
    }

    int yRepeat = size.height / source.size().height;
    if (thresholdImage.size().height % source.size().height != 0) {
        yRepeat += 1;
    }

    cv::Mat repeat;
    cv::repeat(source, yRepeat, xRepeat, repeat);
    cv::Rect cropRect = cv::Rect(0,0,size.width,size.height);
    cv::Mat cropped = repeat(cropRect);
    patternImage = cropped;
}

+(UIImage* _Nullable) fill:(CGPoint)point
                         r:(int)r
                         g:(int)g
                         b:(int)b {
    int pointColor = thresholdImage.at<uchar>(point.x, point.y);
    if (pointColor == 0) {
        return NULL;
    } else {
        cv::Size size = [self getMaskSize];
        cv::Mat mask = cv::Mat::zeros(size, CV_8UC1);
        cv::Scalar color = cv::Scalar(r, g, b);
        cv::Point cvPoint = cv::Point(point.x, point.y);
        cv::floodFill(thresholdImage,
                      mask,
                      cvPoint,
                      cv::Scalar(255),
                      0,
                      cv::Scalar(0),
                      cv::Scalar(0),
                      4 + (255 << 8) + cv::FLOODFILL_MASK_ONLY);
        cv::bitwise_not(mask, invertedMask);
        cv::Mat draw = cv::Mat::zeros(size, CV_8UC3);
        cv::Mat filled = cv::Mat(size, CV_8UC3, color);
        cv::copyTo(draw, filled, invertedMask);
        cv::Mat rgba;
        cv::cvtColor(filled, rgba, cv::COLOR_RGB2RGBA);
        cv::Mat channels[4];
        cv::split(rgba, channels);
        channels[3] = mask;
        cv::Mat dst;
        cv::merge(channels, 4, dst);
        return MatToUIImage(dst);
    }
}

+(void) makeMask:(CGPoint)point {
    int pointColor = thresholdImage.at<uchar>(point.x, point.y);
    points.clear();
    if (pointColor == 0) {
        hasMask = false;
    } else {
        hasMask = true;
        cv::Size size = [self getMaskSize];
        cv::Mat mask = cv::Mat::zeros(size, CV_8UC1);
        cv::Point cvPoint = cv::Point(point.x, point.y);
        cv::floodFill(thresholdImage,
                      mask,
                      cvPoint,
                      cv::Scalar(255),
                      0,
                      cv::Scalar(0),
                      cv::Scalar(0),
                      4 + (255 << 8) + cv::FLOODFILL_MASK_ONLY);
        maskImage = mask;
        cv::bitwise_not(mask, invertedMask);
        strokeImage = cv::Mat::zeros(size, CV_8UC1);
    }
}

+(void) updatePoint:(CGPoint)point {
    cv::Point cvPoint = cv::Point(point.x, point.y);
    points.push_back(cvPoint);
}

+(int) getRandomNumberBetween:(int)from
                           to:(int)to {
    return (int)from + arc4random() % (to-from+1);
}

+(UIImage* _Nullable) erase:(double)size {
    return [self drawLine:size r:255 g:255 b:255];
}

+(UIImage* _Nullable) drawLine:(double)size
                             r:(int)r
                             g:(int)g
                             b:(int)b {
    if (!hasMask) {
        return NULL;
    }

    if (points.size() <= 0) {
        return NULL;
    }

    cv::Mat draw = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    int idx;
    for (idx = 0; idx < points.size() - 1; idx++) {
        cv::Point point1 = points[idx];
        cv::Point point2 = points[idx + 1];
        cv::line(draw, point1, point2, cv::Scalar(255), size);
    }

    strokeImage = strokeImage + draw;

    cv::Point lastPoint = points[points.size() - 1];
    points.clear();
    points.push_back(lastPoint);

    cv::Mat empty = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    cv::copyTo(empty, strokeImage, invertedMask);
    cv::Mat invertedStroke;
    cv::bitwise_not(strokeImage, invertedStroke);
    cv::Mat rgba;
    cv::cvtColor(strokeImage, rgba, cv::COLOR_GRAY2RGBA);
    cv::Mat channels[4];
    cv::split(rgba, channels);
    channels[0] = r;
    channels[1] = g;
    channels[2] = b;
    channels[3] = strokeImage;
    cv::Mat dst;
    cv::merge(channels, 4, dst);
    return MatToUIImage(dst);
}

+(UIImage* _Nullable) drawPencil:(double)size
                               r:(int)r
                               g:(int)g
                               b:(int)b {
    if (!hasMask) {
        return NULL;
    }

    if (points.size() <= 0) {
        return NULL;
    }

    cv::Mat draw = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    int idx;
    for (idx = 0; idx < points.size() - 1; idx++) {
        cv::Point point1 = points[idx];
        cv::Point point2 = points[idx + 1];
        cv::line(draw, point1, point2, cv::Scalar(255), size);
    }

    cv::Mat resize;
    cv::resize(draw, resize, cv::Size(256, 256));
    cv::Mat randomImage = cv::Mat::zeros(resize.size(), CV_8UC1);
    for (int i = 0; i < resize.size().width; i++) {
        for (int j = 0; j < resize.size().height; j++) {
            if (resize.at<uchar>(j, i) != 0) {
                int random = [self getRandomNumberBetween:0 to:255];
                randomImage.at<uchar>(j, i) = random;
            } else {
                randomImage.at<uchar>(j, i) = 0;
            }
        }
    }

    cv::Mat originSize;
    cv::resize(randomImage, originSize, strokeImage.size());
    strokeImage = strokeImage + originSize;

    cv::Point lastPoint = points[points.size() - 1];
    points.clear();
    points.push_back(lastPoint);

    cv::Mat strokeThres;
    cv::threshold(strokeImage, strokeThres, 60, 255, cv::THRESH_BINARY);
    cv::Mat empty = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    cv::copyTo(empty, strokeThres, invertedMask);
    cv::Mat channels[4];
    cv::Mat pattern = patternImage.clone();
    cv::split(pattern, channels);
    channels[3] = strokeThres;
    cv::Mat dst;
    cv::merge(channels, 4, dst);
    return MatToUIImage(dst);
}

+(UIImage* _Nullable) drawCrayon:(double)size
                               r:(int)r
                               g:(int)g
                               b:(int)b {
    if (!hasMask) {
        return NULL;
    }

    if (points.size() <= 0) {
        return NULL;
    }

    cv::Mat draw = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    int idx;
    for (idx = 0; idx < points.size() - 1; idx++) {
        cv::Point point1 = points[idx];
        cv::Point point2 = points[idx + 1];
        cv::line(draw, point1, point2, cv::Scalar(255), size);
    }

    cv::Mat resize;
    cv::resize(draw, resize, cv::Size(256, 256));
    cv::Mat randomImage = cv::Mat::zeros(resize.size(), CV_8UC1);
    for (int i = 0; i < resize.size().width; i++) {
        for (int j = 0; j < resize.size().height; j++) {
            if (resize.at<uchar>(j, i) != 0) {
                int random = [self getRandomNumberBetween:0 to:255];
                randomImage.at<uchar>(j, i) = random;
            } else {
                randomImage.at<uchar>(j, i) = 0;
            }
        }
    }

    cv::threshold(randomImage, randomImage, 180, 255, cv::THRESH_BINARY);
    cv::dilate(randomImage, randomImage, cv::Mat(), cv::Point(-1, -1), 1, 1, 1);
    cv::erode(randomImage, randomImage, cv::Mat(), cv::Point(-1, -1), 1, 1, 1);
    cv::GaussianBlur(randomImage, randomImage, cv::Size(5, 5), -1);
    cv::Mat thres1;
    cv::threshold(randomImage, thres1, 140, 255, cv::THRESH_BINARY);
    cv::Mat thres2;
    cv::threshold(randomImage, thres2, 190, 255, cv::THRESH_BINARY);
    cv::Mat originSize1;
    cv::resize(thres1, originSize1, strokeImage.size());
    cv::Mat originSize2;
    cv::resize(thres2, originSize2, strokeImage.size());
    strokeImage = strokeImage + originSize1 + originSize2;

    cv::Point lastPoint = points[points.size() - 1];
    points.clear();
    points.push_back(lastPoint);

    cv::Mat empty = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    cv::copyTo(empty, strokeImage, invertedMask);
    cv::Mat invertedStroke;
    cv::bitwise_not(strokeImage, invertedStroke);
    cv::Mat rgba;
    cv::cvtColor(strokeImage, rgba, cv::COLOR_GRAY2RGBA);
    cv::Mat channels[4];
    cv::split(rgba, channels);
    channels[0] = r;
    channels[1] = g;
    channels[2] = b;
    channels[3] = strokeImage;
    cv::Mat dst;
    cv::merge(channels, 4, dst);
    return MatToUIImage(dst);
}

+(UIImage* _Nullable) drawBrush:(double)size
                              r:(int)r
                              g:(int)g
                              b:(int)b {
    if (!hasMask) {
        return NULL;
    }

    if (points.size() <= 0) {
        return NULL;
    }

    cv::Mat draw = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    int idx;
    for (idx = 0; idx < points.size() - 1; idx++) {
        cv::Point point1 = points[idx];
        cv::Point point2 = points[idx + 1];
        cv::line(draw, point1, point2, cv::Scalar(255), size);
    }

    cv::Mat resize;
    cv::resize(draw, resize, cv::Size(256, 256));
    cv::Mat randomImage = cv::Mat::zeros(resize.size(), CV_8UC1);
    for (int i = 0; i < resize.size().width; i++) {
        for (int j = 0; j < resize.size().height; j++) {
            if (resize.at<uchar>(j, i) != 0) {
                int random = [self getRandomNumberBetween:0 to:255];
                randomImage.at<uchar>(j, i) = random;
            } else {
                randomImage.at<uchar>(j, i) = 0;
            }
        }
    }

    cv::threshold(randomImage, randomImage, 160, 255, cv::THRESH_BINARY);
    cv::dilate(randomImage, randomImage, cv::Mat(), cv::Point(-1, -1), 1, 1, 1);
    cv::erode(randomImage, randomImage, cv::Mat(), cv::Point(-1, -1), 1, 1, 1);
    cv::GaussianBlur(randomImage, randomImage, cv::Size(5, 5), -1);
    cv::threshold(randomImage, randomImage, 230, 255, cv::THRESH_BINARY);
    cv::dilate(randomImage, randomImage, cv::Mat(), cv::Point(-1, -1), 2, 1, 1);
    cv::GaussianBlur(randomImage, randomImage, cv::Size(3, 3), -1);
    cv::Mat originSize;
    cv::resize(randomImage, originSize, strokeImage.size());
    strokeImage = strokeImage + originSize;

    cv::Point lastPoint = points[points.size() - 1];
    points.clear();
    points.push_back(lastPoint);

    cv::Mat empty = cv::Mat::zeros(strokeImage.size(), CV_8UC1);
    cv::copyTo(empty, strokeImage, invertedMask);
    cv::Mat invertedStroke;
    cv::bitwise_not(strokeImage, invertedStroke);
    cv::Mat rgba;
    cv::cvtColor(strokeImage, rgba, cv::COLOR_GRAY2RGBA);
    cv::Mat channels[4];
    cv::split(rgba, channels);
    channels[0] = r;
    channels[1] = g;
    channels[2] = b;
    channels[3] = strokeImage / 2;
    cv::Mat dst;
    cv::merge(channels, 4, dst);
    return MatToUIImage(dst);
}

+(void) touchEnded {
    hasMask = false;
    points.clear();
}

@end
