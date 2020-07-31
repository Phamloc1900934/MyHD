#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

#include "speedladder.h"


SpeedLadder::SpeedLadder(QQuickItem *parent): QQuickPaintedItem(parent) {
    qDebug() << "SpeedLadder::SpeedLadder()";

}

void SpeedLadder::paint(QPainter* painter) {
    painter->save();

    QFont font("sans-serif", 11, 1, false);

    painter->setFont(font);

    auto openhd = OpenHD::instance();

    auto _airspeed = openhd->m_airspeed;
    auto _speed = openhd->m_speed;

    auto speed = m_imperial ? (m_airspeedOrGps ? (_airspeed * 0.621371) : (_speed * 0.621371)) :
                              (m_airspeedOrGps ? _airspeed : _speed);

    //weird rounding issue where decimals make ladder dissappear
    speed = round(speed);

    // ticks right/left position
    auto x = 32;

    // ladder center up/down..tweak
    auto y_position = height() / 2 + 11;

    // ladder labels right/left position
    auto x_label = 10;

    auto ratio_speed = height() / m_speedRange;

    int k;
    int y;

    for (k = (speed - m_speedRange / 2); k <= speed + m_speedRange / 2; k++) {
        y =  y_position + ((k - speed) * ratio_speed) * -1;
        if (k % 10 == 0) {
            if (k >= 0) {
                // big ticks
                painter->fillRect(QRectF(x, y, 12, 3), m_color);

                if (k > speed + 5 || k < speed - 5) {
                    painter->drawText(x_label, y + 6, QString(k));
                }
            }
            if (k < m_speedMinimum) {
                //start position speed (squares) below "0"
                painter->fillRect(QRectF(x, y - 12, 15, 15), m_color);
            }
        }
        else if ((k % 5 == 0) && (k > m_speedMinimum)) {
            //little ticks
            painter->fillRect(QRectF(x + 5, y, 7, 2), m_color);
        }
    }

    painter->restore();
}


QColor SpeedLadder::color() const {
    return m_color;
}


void SpeedLadder::setColor(QColor color) {
    m_color = color;
    emit colorChanged(m_color);
    update();
}


void SpeedLadder::setAirspeedOrGps(bool airspeedOrGps) {
    m_airspeedOrGps = airspeedOrGps;
    emit airspeedOrGpsChanged(m_airspeedOrGps);
    update();
}


void SpeedLadder::setImperial(bool imperial) {
    m_imperial = imperial;
    emit imperialChanged(m_imperial);
    update();
}


void SpeedLadder::setSpeedMinimum(int speedMinimum) {
    m_speedMinimum = speedMinimum;
    emit speedMinimumChanged(m_speedMinimum);
    update();
}


void SpeedLadder::setSpeedRange(int speedRange) {
    m_speedRange = speedRange;
    emit speedRangeChanged(m_speedRange);
    update();
}
