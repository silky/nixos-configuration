#include "btop_follow.hpp"

#include <cassert>
#include <filesystem>
#include <iostream>

struct Process {
    uint64_t pid, ppid, cpu_s;
    char state = 'S';
};

int main() {
    using namespace WindowFollow;
    const auto root = parse("123 100\n");
    assert(root.kind == Kind::process && root.pid == 123 && root.start_time == 100);
    for (const auto* invalid : {"", "123", "123 0", "0 1", "-123 1", "123 -1",
                               "123x 1", "123 1 extra", "2147483648 1", "99999999999999999999999 1"})
        assert(parse(invalid).kind == Kind::unavailable);
    assert(parse("waiting\n").kind == Kind::waiting);
    assert(parse("waiting 123").kind == Kind::unavailable);

    std::vector<Process> processes{{1, 0, 1}, {123, 1, 100}, {124, 123, 101},
                                 {125, 124, 102}, {1234, 1, 99}, {126, 123, 103, 'X'}};
    Filter filter;
    assert(filter.refresh(root, true, processes));
    assert(filter.alive && filter.includes(123) && filter.includes(124) && filter.includes(125));
    assert(!filter.includes(1) && !filter.includes(1234) && !filter.includes(126));
    assert(!filter.refresh(root, true, processes));

    // Following discovers new descendants and tracks reparenting.
    processes.push_back({127, 125, 104});
    filter.refresh(root, true, processes);
    assert(filter.includes(127));
    processes[2].ppid = 1;
    filter.refresh(root, true, processes);
    assert(!filter.includes(124) && !filter.includes(125) && !filter.includes(127));

    // A reused PID must not attach the target to a different process.
    processes[1].cpu_s = 999;
    filter.refresh(root, true, processes);
    assert(!filter.alive && !filter.includes(123) && !filter.includes(124));
    assert(filter.label().find("exited PID 123") != std::string::npos);
    filter.refresh(parse("123 999"), true, processes);
    assert(filter.alive && filter.includes(123));

    // Off and initial waiting leave the ordinary process list intact.
    filter.refresh(root, false, processes);
    assert(!filter.scoped() && filter.includes(1234));
    filter.refresh({Kind::waiting}, true, processes);
    assert(!filter.scoped() && filter.includes(1234));
    filter.refresh({Kind::unavailable}, true, processes);
    assert(filter.scoped() && !filter.includes(1234));

    // A malformed ancestry cycle cannot hang the membership traversal.
    processes = {{123, 125, 100}, {124, 123, 101}, {125, 124, 102}};
    filter.refresh(root, true, processes);
    assert(filter.includes(123) && filter.includes(124) && filter.includes(125));

    const std::string path = "window-follow-stat-fixture";
    {
        std::ofstream output(path);
        output << "123 (a name ) with (parens)) S 42";
        for (int field = 5; field < 22; ++field) output << " 0";
        output << " 987 0 0\n";
    }
    const auto identity = read_identity(path);
    assert(identity && identity->ppid == 42 && identity->start_time == 987);
    std::filesystem::remove(path);
    assert(!read_identity(path));
    assert(read_target(path) == "unavailable");
    std::cout << "Window subtree identity and membership tests passed\n";
}
