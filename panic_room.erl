-module(panic_room).

-behaviour(gen_server).

-define(DEFAULT_PERIOD_MS, 60000).

%% API
-export([
    start_link/0,
    start_link/1
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(SERVER, ?MODULE).

-record(state, {
    rn = 0,
    rtimer,
    rfile,

    mqln = 0,
    mqltimer,
    mqlfile,

    mn = 0,
    mtimer,
    mfile,

    %% TODO: provide args to use it
    dmn = 0,
    dmtimer,
    prev_mem_num = [],
    dmfile,

    drn = 0,
    drtimer,
    prev_reducts = [],
    drfile,

    measure_timer,
    measurefile
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link(?MODULE, [], []).

start_link(Config) ->
    gen_server:start_link(?MODULE, Config, []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([{reductions, RPeriod, RN}, {message_queue_len, MQLPeriod, MQLN}, {memory, MPeriod, MN}]) when
    RPeriod > 0 andalso MQLPeriod > 0 andalso MPeriod > 0
->
    {ok, RTRef} = timer:send_interval(RPeriod, self(), reductions),
    {ok, MQLTRef} = timer:send_interval(MQLPeriod, self(), message_queue_len),
    {ok, MTRef} = timer:send_interval(MPeriod, self(), memory),
    {ok, #state{
        rn = RN,
        rtimer = RTRef,
        mqln = MQLN,
        mqltimer = MQLTRef,
        mn = MN,
        mtimer = MTRef
    }};
init([]) ->
    {ok, MeasTRef} = timer:send_interval(?DEFAULT_PERIOD_MS, self(), measure),
    {ok, #state{
        measure_timer = MeasTRef
    }}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(reductions, #state{rn = RN, rfile = RFile} = State) when RN > 0 ->
    ReductList = lists:foldl(
        fun(P, Acc) ->
            case process_info(P, reductions) of
                undefined -> Acc;
                {_, R} -> [{P, R} | Acc]
            end
        end,
        [],
        processes()
    ),
    [{Pid, _} = A, B, C, D, E, F, G, H, I, J | _] = lists:sort(
        fun({_, X}, {_, Y}) -> X > Y end, ReductList
    ),
    {ok, File} = find_file("reductions", RFile),
    io:format(
        File,
        "~n------TOP 10 REDUCTIONS-----~p~n   ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n",
        [
            {Pid, process_info(element(1, A), initial_call),
                process_info(element(1, A), dictionary), process_info(element(1, A), reductions)},
            {
                process_info(element(1, B), initial_call),
                process_info(element(1, B), dictionary),
                process_info(element(1, B), reductions)
            },
            {
                process_info(element(1, C), initial_call),
                process_info(element(1, C), dictionary),
                process_info(element(1, C), reductions)
            },
            {
                process_info(element(1, D), initial_call),
                process_info(element(1, D), dictionary),
                process_info(element(1, D), reductions)
            },
            {
                process_info(element(1, E), initial_call),
                process_info(element(1, E), dictionary),
                process_info(element(1, E), reductions)
            },
            {
                process_info(element(1, F), initial_call),
                process_info(element(1, F), dictionary),
                process_info(element(1, F), reductions)
            },
            {
                process_info(element(1, G), initial_call),
                process_info(element(1, G), dictionary),
                process_info(element(1, G), reductions)
            },
            {
                process_info(element(1, H), initial_call),
                process_info(element(1, H), dictionary),
                process_info(element(1, H), reductions)
            },
            {
                process_info(element(1, I), initial_call),
                process_info(element(1, I), dictionary),
                process_info(element(1, I), reductions)
            },
            {
                process_info(element(1, J), initial_call),
                process_info(element(1, J), dictionary),
                process_info(element(1, J), reductions)
            }
        ]
    ),
    {noreply, State#state{rn = RN - 1, rfile = File}};
handle_info(reductions, #state{rtimer = RTRef, rfile = RFile} = State) ->
    _ = file:close(RFile),
    {ok, cancel} = timer:cancel(RTRef),
    {noreply, State#state{rtimer = undefined, rfile = undefined}};
handle_info(message_queue_len, #state{mqln = MQLN, mqlfile = MQLFile} = State) when MQLN > 0 ->
    TotalList = lists:foldl(
        fun(P, Acc) ->
            case process_info(P, message_queue_len) of
                undefined -> Acc;
                {_, L} -> [{P, L} | Acc]
            end
        end,
        [],
        processes()
    ),
    [{Pid, _} = A, B, C, D, E, F, G, H, I, J | _] = lists:sort(
        fun({_, X}, {_, Y}) -> X > Y end, TotalList
    ),
    {ok, File} = find_file("mql", MQLFile),
    io:format(
        File,
        "~n------TOP 10 MESSAGE Q LEN-----~p~n   ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n    ~p~n",
        [
            {Pid, process_info(element(1, A), initial_call),
                process_info(element(1, A), dictionary),
                process_info(element(1, A), message_queue_len)},
            {
                process_info(element(1, B), initial_call),
                process_info(element(1, B), dictionary),
                process_info(element(1, B), message_queue_len)
            },
            {
                process_info(element(1, C), initial_call),
                process_info(element(1, C), dictionary),
                process_info(element(1, C), message_queue_len)
            },
            {
                process_info(element(1, D), initial_call),
                process_info(element(1, D), dictionary),
                process_info(element(1, D), message_queue_len)
            },
            {
                process_info(element(1, E), initial_call),
                process_info(element(1, E), dictionary),
                process_info(element(1, E), message_queue_len)
            },
            {
                process_info(element(1, F), initial_call),
                process_info(element(1, F), dictionary),
                process_info(element(1, F), message_queue_len)
            },
            {
                process_info(element(1, G), initial_call),
                process_info(element(1, G), dictionary),
                process_info(element(1, G), message_queue_len)
            },
            {
                process_info(element(1, H), initial_call),
                process_info(element(1, H), dictionary),
                process_info(element(1, H), message_queue_len)
            },
            {
                process_info(element(1, I), initial_call),
                process_info(element(1, I), dictionary),
                process_info(element(1, I), message_queue_len)
            },
            {
                process_info(element(1, J), initial_call),
                process_info(element(1, J), dictionary),
                process_info(element(1, J), message_queue_len)
            }
        ]
    ),
    {noreply, State#state{mqln = MQLN - 1, mqlfile = File}};
handle_info(message_queue_len, #state{mqltimer = MQLTRef, mqlfile = MQLFile} = State) ->
    ok = file:close(MQLFile),
    {ok, cancel} = timer:cancel(MQLTRef),
    {noreply, State#state{mqltimer = undefined, mqlfile = undefined}};
handle_info(memory, #state{mn = MN, mfile = MFile} = State) when MN > 0 ->
    Res = lists:foldl(
        fun(P, Acc) ->
            case process_info(P) of
                undefined ->
                    Acc;
                Info ->
                    case proplists:get_value(dictionary, Info) of
                        [] ->
                            GroupLeaderP = proplists:get_value(group_leader, Info),
                            _InitCall = proplists:get_value(initial_call, Info),
                            TotalHeapS = proplists:get_value(total_heap_size, Info),
                            RealHeapSize =
                                TotalHeapS * erlang:system_info(wordsize) / math:pow(1024, 2),
                            case lists:keytake(GroupLeaderP, 1, Acc) of
                                {value, {GroupLeaderP, CurrentTotalHeapS, CurrentCounter}, Acc1} ->
                                    [
                                        {GroupLeaderP, CurrentTotalHeapS + RealHeapSize,
                                            CurrentCounter + 1}
                                        | Acc1
                                    ];
                                _ ->
                                    [{GroupLeaderP, RealHeapSize, 1} | Acc]
                            end;
                        Data ->
                            InitCall =
                                case proplists:get_value('$initial_call', Data) of
                                    undefined ->
                                        proplists:get_value(initial_call, Info);
                                    Any ->
                                        Any
                                end,
                            TotalHeapS = proplists:get_value(total_heap_size, Info),
                            RealHeapSize =
                                TotalHeapS * erlang:system_info(wordsize) / math:pow(1024, 2),
                            case lists:keytake(InitCall, 1, Acc) of
                                {value, {InitCall, CurrentTotalHeapS, CurrentCounter}, Acc1} ->
                                    [
                                        {InitCall, CurrentTotalHeapS + RealHeapSize,
                                            CurrentCounter + 1}
                                        | Acc1
                                    ];
                                _ ->
                                    [{InitCall, RealHeapSize, 1} | Acc]
                            end
                    end
            end
        end,
        [],
        processes()
    ),
    SortedRes = lists:sort(fun({_, X, _}, {_, Y, _}) -> X > Y end, Res),
    {ok, File} = find_file("memory", MFile),

    ChildrenData = supervisor:count_children(cvi_stat_session_handler_sup),
    [
        {total, _T},
        {processes, _P},
        {processes_used, PU},
        {system, _SYS},
        {atom, _A},
        {atom_used, _AU},
        {binary, Bin},
        {code, _Code},
        {ets, ETS}
    ] = erlang:memory(),

    io:format(
        File,
        "~n~p------MEMORY STATS-----~10000p~nChildrenData ~p~n Memory ETS ~p~n Memory Bin ~p~n Memory PU ~p~n",
        [
            erlang:system_time(second),
            SortedRes,
            ChildrenData,
            ETS / 1024 / 1024,
            Bin / 1024 / 1024,
            PU / 1024 / 1024
        ]
    ),

    {noreply, State#state{mn = MN - 1, mfile = File}};
handle_info(memory, #state{mtimer = MTRef, mfile = MFile} = State) ->
    ok = file:close(MFile),
    {ok, cancel} = timer:cancel(MTRef),
    {noreply, State#state{mtimer = undefined, mfile = undefined}};
handle_info(memory_diff_sort, #state{dmn = DMN, prev_mem_num = Prev, dmfile = DMFile} = State) when
    DMN > 0
->
    MemNum = lists:foldl(
        fun(P, Acc) ->
            case process_info(P) of
                undefined ->
                    Acc;
                Info ->
                    case proplists:get_value(dictionary, Info) of
                        [] ->
                            GroupLeaderP = proplists:get_value(group_leader, Info),
                            _InitCall = proplists:get_value(initial_call, Info),
                            TotalHeapS = proplists:get_value(total_heap_size, Info),
                            RealHeapSize =
                                TotalHeapS * erlang:system_info(wordsize) / math:pow(1024, 2),
                            case lists:keytake(GroupLeaderP, 1, Acc) of
                                {value, {GroupLeaderP, CurrentTotalHeapS, CurrentCounter}, Acc1} ->
                                    [
                                        {GroupLeaderP, CurrentTotalHeapS + RealHeapSize,
                                            CurrentCounter + 1}
                                        | Acc1
                                    ];
                                _ ->
                                    [{GroupLeaderP, RealHeapSize, 1} | Acc]
                            end;
                        Data ->
                            InitCall =
                                case proplists:get_value('$initial_call', Data) of
                                    undefined ->
                                        proplists:get_value(initial_call, Info);
                                    Any ->
                                        Any
                                end,
                            TotalHeapS = proplists:get_value(total_heap_size, Info),
                            RealHeapSize =
                                TotalHeapS * erlang:system_info(wordsize) / math:pow(1024, 2),
                            case lists:keytake(InitCall, 1, Acc) of
                                {value, {InitCall, CurrentTotalHeapS, CurrentCounter}, Acc1} ->
                                    [
                                        {InitCall, CurrentTotalHeapS + RealHeapSize,
                                            CurrentCounter + 1}
                                        | Acc1
                                    ];
                                _ ->
                                    [{InitCall, RealHeapSize, 1} | Acc]
                            end
                    end
            end
        end,
        [],
        processes()
    ),

    {ok, File} = find_file(
        "mem_num." ++ integer_to_list(erlang:system_time(second)) ++ "." ++
            integer_to_list(cpu_sup:avg1()),
        DMFile,
        [write]
    ),

    DiffMem = lists:foldl(
        fun({FunCall, HeapSize, InstanceCounter}, Acc) ->
            case lists:keyfind(FunCall, 1, Prev) of
                {FunCall, HeapSize0, _} when HeapSize - HeapSize0 > 0 ->
                    [{FunCall, HeapSize - HeapSize0, InstanceCounter} | Acc];
                _ ->
                    Acc
            end
        end,
        [],
        MemNum
    ),
    SortDiff = lists:sort(fun({_, X, _}, {_, Y, _}) -> X > Y end, DiffMem),

    io:format(File, "~n~p------MEMORY DIFF per process pool ~p~n-----Diff ~10000p~n", [
        erlang:system_time(second), cpu_sup:avg1(), SortDiff
    ]),

    {noreply, State#state{dmn = DMN - 1, prev_mem_num = MemNum, dmfile = File}};
handle_info(memory_diff_sort, #state{dmtimer = DMTRef, dmfile = DMFile} = State) ->
    ok = file:close(DMFile),
    {ok, cancel} = timer:cancel(DMTRef),
    {noreply, State#state{dmtimer = undefined, prev_mem_num = [], dmfile = undefined}};
handle_info(
    reductions_diff_sort, #state{drn = DRN, prev_reducts = Prev, drfile = DRFile} = State
) when DRN > 0 ->
    Reducts = lists:foldl(
        fun(P, Acc) ->
            case process_info(P) of
                undefined ->
                    Acc;
                Info ->
                    case proplists:get_value(dictionary, Info) of
                        [] ->
                            GroupLeaderP = proplists:get_value(group_leader, Info),
                            _InitCall = proplists:get_value(initial_call, Info),
                            Reducts = proplists:get_value(reductions, Info),
                            [{GroupLeaderP, Reducts} | Acc];
                        Data ->
                            InitCall =
                                case proplists:get_value('$initial_call', Data) of
                                    undefined ->
                                        proplists:get_value(initial_call, Info);
                                    Any ->
                                        Any
                                end,
                            Reducts = proplists:get_value(reductions, Info),
                            [{InitCall, Reducts} | Acc]
                    end
            end
        end,
        [],
        processes()
    ),

    DiffReds = lists:foldl(
        fun({FunCall, Reds}, Acc) ->
            case lists:keyfind(FunCall, 1, Prev) of
                {FunCall, Reducts0} when Reds - Reducts0 > 0 ->
                    [{FunCall, Reds - Reducts0} | Acc];
                _ ->
                    Acc
            end
        end,
        [],
        Reducts
    ),
    SortDiff = lists:sort(fun({_, X}, {_, Y}) -> X > Y end, DiffReds),

    {ok, File} = find_file("reductions_diff", DRFile),

    io:format(File, "~n~p------REDUCTS DIFF per process ~p~n-----Diff ~10000p~n", [
        erlang:system_time(second), cpu_sup:avg1(), SortDiff
    ]),

    {noreply, State#state{drn = DRN - 1, drfile = File}};
handle_info(reductions_diff_sort, #state{drtimer = DRRef, drfile = DRFile} = State) ->
    ok = file:close(DRFile),
    {ok, cancel} = timer:cancel(DRRef),
    {noreply, State#state{drtimer = undefined, prev_reducts = [], drfile = undefined}};
handle_info(measure, #state{measurefile = MsrFile} = State) ->
    {ok, File} = find_file("cpu", MsrFile),
    Util = cpu_sup:util([per_cpu]),
    Avg1 = cpu_sup:avg1() / 256,
    io:format(File, "~n~p------MEASURE CPU UTIL ~10000p~n-----CPU AVG1 ~p~n", [
        erlang:system_time(second), Util, Avg1
    ]),
    {noreply, State#state{measurefile = File}}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

find_file(FileName, File) ->
    find_file(FileName, File, [append]).

find_file(FileName, undefined, Mode) ->
    file:open("/tmp/" ++ FileName, Mode);
find_file(_FileName, File, _Mode) ->
    {ok, File}.
