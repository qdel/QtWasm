#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtPlugin>
#include <string>
#include <fstream>
#include <thread>
#include <iostream>

static void PrintFileContent (const char * filename) {
    std::ifstream myfile (filename);
    if (!myfile.is_open())
        return;

    std::string line;
    while (getline(myfile,line))
        std::cout << line << '\n';
}

void ThreadFunction () {
    std::cout << "Hello thread\n";
}
QGuiApplication*    g_app = nullptr;

int main(int argc, char *argv[])
{
    std::cout << "Qt version " << QT_VERSION_STR << std::endl;

    PrintFileContent("example.txt");

    try {
        throw std::runtime_error("Hello runtime_error");
    } catch (std::exception & e) {
        std::cout << "Exception catching works as expected: " << e.what() << std::endl;
    }

    try {
        std::thread t(&ThreadFunction);
        t.join();
        std::cout << "Thread joined\n";
    } catch (std::exception & e) {
        std::cerr << "ERROR: " << e.what() << std::endl;
        return -1;
    }

    g_app = new QGuiApplication(argc, argv);
    QQmlApplicationEngine* engine = new QQmlApplicationEngine(g_app);
    engine->load(QUrl(QStringLiteral("qrc:/main.qml")));

    return 0;
}
