const std = @import("std");

const Process = struct {
    id: usize,
    arrival_time: i32,
    burst_time: i32,
    completion_time: i32 = 0,
    turnaround_time: i32 = 0,
    waiting_time: i32 = 0,
};

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open input file
    const input_file = try std.fs.cwd().openFile("input1.txt", .{});
    defer input_file.close();

    // Create output file
    const output_file = try std.fs.cwd().createFile("output.txt", .{});
    defer output_file.close();

    var processes = std.ArrayList(Process).init(allocator);
    defer processes.deinit();

    // Read input file
    var buf_reader = std.io.bufferedReader(input_file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var id: usize = 1;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        // Trim whitespace
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0) continue;

        var it = std.mem.split(u8, trimmed, " ");
        const at_str = it.next() orelse return error.InvalidFormat;
        const bt_str = it.next() orelse return error.InvalidFormat;

        const at = try std.fmt.parseInt(i32, at_str, 10);
        const bt = try std.fmt.parseInt(i32, bt_str, 10);

        try processes.append(.{
            .id = id,
            .arrival_time = at,
            .burst_time = bt,
        });
        id += 1;
    }

    // Calculate times
    var current_time: i32 = 0;
    for (processes.items) |*process| {
        if (current_time < process.arrival_time) {
            current_time = process.arrival_time;
        }
        process.completion_time = current_time + process.burst_time;
        process.turnaround_time = process.completion_time - process.arrival_time;
        process.waiting_time = process.turnaround_time - process.burst_time;
        current_time = process.completion_time;
    }

    // Write results to output file
    const writer = output_file.writer();
    try writer.print("FCFS CPU Scheduling Algorithm Results\n", .{});
    try writer.print("------------------------------------\n", .{});
    try writer.print("PID\tAT\tBT\tCT\tTAT\tWT\n", .{});

    var total_tat: i32 = 0;
    var total_wt: i32 = 0;

    for (processes.items) |process| {
        try writer.print("{d}\t{d}\t{d}\t{d}\t{d}\t{d}\n", .{
            process.id,
            process.arrival_time,
            process.burst_time,
            process.completion_time,
            process.turnaround_time,
            process.waiting_time,
        });
        total_tat += process.turnaround_time;
        total_wt += process.waiting_time;
    }

    const avg_tat = @as(f32, @floatFromInt(total_tat)) / @as(f32, @floatFromInt(processes.items.len));
    const avg_wt = @as(f32, @floatFromInt(total_wt)) / @as(f32, @floatFromInt(processes.items.len));

    try writer.print("\nAverage Turnaround Time: {d:.2}\n", .{avg_tat});
    try writer.print("Average Waiting Time: {d:.2}\n", .{avg_wt});
}
