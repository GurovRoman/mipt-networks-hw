#include <iostream>
#include <atomic>
#include <thread>
#include <mutex>
#include <string>
#include <vector>
#include <random>
#include <chrono>


using namespace std::string_literals;


std::atomic<int> cable {0};

const int CARRIER_FREQ = 512;
const size_t MAX_ATTEMPT = 5;
const size_t FRAME_TIME_MSEC = 4;
const std::string MSG(1024, 'N');
const size_t MAX_MSGS = 2;

std::mutex log_mutex;


void logWrite(const std::string& msg) {
    static auto start_time = std::chrono::steady_clock::now();
    std::unique_lock lock {log_mutex};
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - start_time);
    std::cout << '[' << timestamp.count() << "] " << msg << std::endl;
}


auto getSleepTime(size_t collision_count) {
    static thread_local std::mt19937 gen(std::random_device{}());
    std::uniform_int_distribution<std::chrono::milliseconds::rep> rd(FRAME_TIME_MSEC,
                                                                     (collision_count + 1) * FRAME_TIME_MSEC);
    return std::chrono::milliseconds(rd(gen));
}


void routine(size_t station_id) {
    size_t msgs_left = MAX_MSGS;
    size_t attempt_count = 0;

    while (msgs_left > 0) {

        // Wait if transmission is in progress
        while (cable != 0) {
            sched_yield();
        }

        sched_yield();

        // Transmit carrier frequency during the transmission
        cable += CARRIER_FREQ;

        logWrite("Started transmission attempt "s + std::to_string(attempt_count + 1)
                 + " on station "s + std::to_string(station_id));

        size_t collision_count = 0;

        // Start sending the message
        for (auto& chr : MSG) {
            sched_yield();

            // Send first byte
            auto old_val = cable.fetch_add(chr);

            // Detect collision
            if (old_val != CARRIER_FREQ && collision_count == 0) {
                collision_count = old_val / CARRIER_FREQ - 1;
            }

            sched_yield();

            cable -= chr;
        }

        sched_yield();

        // Finish the transmission
        cable -= CARRIER_FREQ;

        if (collision_count > 0) {
            logWrite("Collision detected during transmission for station "s + std::to_string(station_id));
            ++attempt_count;
            if (attempt_count < MAX_ATTEMPT) {
                std::this_thread::sleep_for(getSleepTime(collision_count));
            } else {
                logWrite("Attempts exceeded for station "s + std::to_string(station_id) + ". Transmission aborted");
                --msgs_left;
            }
        } else {
            --msgs_left;
            attempt_count = 0;
            logWrite("Transmission successfully finished on station "s + std::to_string(station_id));
        }
    }
}


int main(int argc, char** argv) {
    if (argc <= 1) {
        return 1;
    }

    size_t thread_count = std::stoul(argv[1]);

    std::vector<std::thread> threads;

    for (size_t i = 0; i < thread_count; ++i) {
        threads.emplace_back(routine, i);
    }

    for (auto& thread : threads) {
        thread.join();
    }

    return 0;
}
