﻿using EventStore.ClientAPI;
using System;
using System.Threading.Tasks;

namespace Shovel
{
    using System.Collections.Generic;

    public class EventShovel
    {
        private readonly EventShovelConfig _eventShovelConfig;
        private readonly bool _verboseLogging;

        public EventShovel(EventShovelConfig eventShovelConfig)
        {
            _eventShovelConfig = eventShovelConfig;
            _verboseLogging = bool.Parse(Bootstrap.ReadSetting("verboseEventLogs"));
        }

        public void Run()
        {
            long startPosition = long.Parse(Bootstrap.ReadSetting("startPosition"));
            Position streamPosition = new Position(startPosition, 0);
            var maxCount = int.Parse(Bootstrap.ReadSetting("readBatchSize"));
            bool isEndOfStream = false;

            Console.WriteLine($"Shovel start time: {DateTime.Now}");
            while (!isEndOfStream) {
                Console.WriteLine($"Fetching events starting at position: {streamPosition.CommitPosition}");
                var slice = _eventShovelConfig.SourceConnection
                    .ReadAllEventsForwardAsync(streamPosition, maxCount, false, _eventShovelConfig.SourceCredentials)
                    .Result;

                if (_verboseLogging) Console.WriteLine($"Read {slice.Events.Length} events");
                
                streamPosition = slice.NextPosition;
                var eventsByStream = new Dictionary<string, List<EventData>>();

                foreach (var e in slice.Events) {
                    
                    if (ShouldSkipEvent(e)) {
                        if (_verboseLogging) Console.WriteLine(
                            $"Event {e.Event.EventId} of the type {e.Event.EventType} in the stream {e.OriginalStreamId} was filtered out. Skipping it");
                        continue;
                    }

                    if (_verboseLogging) Console.WriteLine($"Creating new EventData for the event {e.Event.EventId}");
                    var stream = e.OriginalStreamId;
                    if (!eventsByStream.ContainsKey(stream)) {
                        eventsByStream.Add(stream, new List<EventData>());
                    }


                    if (_eventShovelConfig.EventTransformer != null) {
                        eventsByStream[stream].AddRange(_eventShovelConfig.EventTransformer.Transform(e));
                    }
                    else {
                        eventsByStream[stream].Add(
                            new EventData(
                                e.Event.EventId,
                                e.Event.EventType,
                                e.Event.IsJson,
                                e.Event.Data,
                                e.Event.Metadata));
                    }
                }

                List<Task<WriteResult>> appendTaskList = new List<Task<WriteResult>>();
                foreach (string stream in eventsByStream.Keys)
                {
                    appendTaskList.Add(_eventShovelConfig.TargetConnection.AppendToStreamAsync(stream,
                        ExpectedVersion.Any, _eventShovelConfig.TargetCredentials,
                        eventsByStream[stream].ToArray()));

                    Console.WriteLine($"Appending {eventsByStream[stream].Count} events to the stream {stream}");
                }
                Console.WriteLine("Awaiting full batch publish");
                Task.WhenAll(appendTaskList).Wait();

                isEndOfStream = slice.IsEndOfStream;
                if (!isEndOfStream) continue;

                Console.WriteLine("Reached end of stream");
                Console.WriteLine($"Shovel end time: {DateTime.Now}");
            }
        }

        private bool ShouldSkipEvent(ResolvedEvent e)
        {
            if (e.Event.EventType.StartsWith("$")) {
                if (_verboseLogging) Console.WriteLine(
                    $"Event {e.Event.EventId} of the type {e.Event.EventType} is internal event. Skipping it");
                return true;
            }

            if (_eventShovelConfig.StreamFilter.Count == 0 && _eventShovelConfig.EventTypeFilter.Count == 0 &&
                _eventShovelConfig.StreamWildcardFilter.Count == 0 &&
                _eventShovelConfig.EventTypeWildcardFilter.Count == 0) {
                return false;
            }

            bool skipForStreamFilter = false;
            if (_eventShovelConfig.StreamFilter.Count != 0) {
                skipForStreamFilter = true;
                foreach (var filter in _eventShovelConfig.StreamFilter) {
                    if (e.OriginalStreamId == filter) {
                        skipForStreamFilter = false;
                        break;
                    }
                }
            }

            bool skipForStreamWildcardFilter = skipForStreamFilter;
            if (_eventShovelConfig.StreamWildcardFilter.Count != 0) {
                skipForStreamWildcardFilter = true;
                foreach (var filter in _eventShovelConfig.StreamWildcardFilter) {
                    if (e.OriginalStreamId.StartsWith(filter)) {
                        skipForStreamWildcardFilter = false;
                        break;
                    }

                }
            }

            bool skipForEventFilter = false;
            if (_eventShovelConfig.EventTypeFilter.Count != 0) {
                skipForEventFilter = true;
                foreach (var filter in _eventShovelConfig.EventTypeFilter) {
                    if (e.Event.EventType == filter) {
                        skipForEventFilter = false;
                        break;
                    }
                }
            }

            bool skipForEventWildcardFilter = skipForEventFilter;
            if (_eventShovelConfig.EventTypeWildcardFilter.Count != 0) {
                skipForEventWildcardFilter = true;
                foreach (var filter in _eventShovelConfig.EventTypeWildcardFilter) {
                    if (e.Event.EventType.StartsWith(filter)) {
                        skipForEventWildcardFilter = false;
                        break;
                    }
                }
            }

            return (skipForStreamFilter && skipForStreamWildcardFilter) || (skipForEventFilter && skipForEventWildcardFilter);
        }
    }
}
