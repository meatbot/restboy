-module(restboy_generator).
-behaviour(gen_server).

%% API.
-export([start_link/0]).

%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

%% STATES
-define(STATE_STOPPED, stopped).
-define(STATE_RUNNING, running).

%% API.

start_link() ->
  logger:notice("~s:~s | starts prime number generator", [?MODULE, ?FUNCTION_NAME]),
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% gen_server.

init([]) ->
  erlang:send_after(0, self(), next),
  State = #{
    state => ?STATE_RUNNING,
    number => 1,
    count => 1
  },
  {ok, State}.

%% Call
handle_call(_Request = state, _From, State) ->
  logger:notice("~s:~s | request \"~p\"", [?MODULE, ?FUNCTION_NAME, _Request]),
  {reply, State, State};
handle_call(_Request, _From, State) ->
  logger:warning("~s:~s | request \"~p\"", [?MODULE, ?FUNCTION_NAME, _Request]),

  {reply, ignored, State}.

%% Cast
%% todo prevent run when state is running
handle_cast(_Msg = run, State) ->
  logger:notice("~s:~s | message \"~p\"", [?MODULE, ?FUNCTION_NAME, _Msg]),
  NewState = State#{
    state => ?STATE_RUNNING
  },
  erlang:send_after(0, self(), next),
  {noreply, NewState};
handle_cast(_Msg = stop, State) ->
  logger:notice("~s:~s | message \"~p\"", [?MODULE, ?FUNCTION_NAME, _Msg]),
  NewState = State#{
    state => ?STATE_STOPPED
  },
  {noreply, NewState};
handle_cast(_Msg, State) ->
  logger:warning("~s:~s | message \"~p\"", [?MODULE, ?FUNCTION_NAME, _Msg]),
  {noreply, State}.

%% Info
handle_info(next, State = #{state := ?STATE_STOPPED}) ->
  {noreply, State};
handle_info(next, State = #{state := ?STATE_RUNNING}) ->
  NextNumber = next_prime(maps:get(number, State)),
  NewCount = maps:get(count, State) + 1,
  NewState = State#{
    number => NextNumber,
    count => NewCount
  },
  erlang:send_after(0, self(), next),
  {noreply, NewState};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

next_prime(N) ->
  Next = N + 2,
  case is_prime(Next) of
    true -> Next;
    false -> next_prime(Next)
  end.

%% todo
is_prime(1) -> true;
is_prime(N) when N rem 2 == 0 -> false;
is_prime(N) -> is_prime(N, N - 2).

is_prime(_N, 1) -> true;
is_prime(N, M) when N rem M == 0 -> false;
is_prime(N, M) -> is_prime(N, M - 2).