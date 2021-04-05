#!/usr/bin/env python3

import sqlite3
import argparse

###############################################################################
#
# Super simple (and probably not very efficient) way to query sqlite file and
# produce a python list of dictionaries with the result of that query
#
###############################################################################
def do_query(sqlite_file, query_string):
    cur = sqlite3.connect(sqlite_file)
    query = cur.execute( query_string )
    colname = [ d[0] for d in query.description ]
    output_list = [ dict(zip(colname, r)) for r in query.fetchall() ]
    cur.close()
    return output_list

###############################################################################
#
# The list of NVTX ranges
#
###############################################################################
class MarkerTable:
    def __init__(self, sqlite_filename):
        self.filename = sqlite_filename
        self.names = []         # map marker.id => marker string value
        self.tids = []          # map marker.id => marker thread id
        self.stack = []
        self.next_idx = int(0)
        self.list = do_query(self.filename,
                             '''
                             select
                                 marker.timestamp,
                                 marker.flags,
                                 marker.id,
                                 StringTable.value,
                                 marker.objectId
                             from cupti_activity_kind_marker as marker
                             inner join StringTable
                                 on marker.name = StringTable._id_
                             order by timestamp''')
        #######################################################################
        # we only want to see kernels invoked during the range of times between
        # when the user started and stopped using nvtx ranges:
        #######################################################################
        self.first_time = self.list[0]['timestamp']
        self.last_time = self.list[-1]['timestamp']

    ###########################################################################
    # pretty print the currently active nvtx ranges
    ###########################################################################
    def cvt_stack_to_string(self, tid_printing):
        output = ''
        for m in self.stack:
            if self.tids[m] == tid_printing: # only elements for this thread
                output = output + self.names[m]+'('+str(m)+'):'
        return output

    ###########################################################################
    # Iterate through marker events for ranges until we're at the state
    # corresponding to input 'tm'
    ###########################################################################
    def update_time(self, tm, tid_printing):
        while self.list[self.next_idx]['timestamp'] <= tm:
            timestamp = self.list[self.next_idx]['timestamp']
            flags     = self.list[self.next_idx]['flags']
            rangeid   = self.list[self.next_idx]['id']
            nm        = self.list[self.next_idx]['value']
            # as per cupti_activity.h: CUpti_ActivityObjectKindId is a 12 byte
            # union, where the threadId (in this case) sits in the middle 4
            # bytes.
            threadid  = int.from_bytes(self.list[self.next_idx]['objectId'][4:8],
                                       byteorder='little', signed=True)

            if flags == 2: # a range starts
                # Range start command gives the name of the range. We want
                # self.names[rangeid]=nm, but need to fill in any holes because
                # Python arrays are dense and start at 0
                while rangeid >= len(self.names):
                    self.names.append(None)
                    self.tids.append(None)
                self.names[rangeid] = nm[:31]
                self.tids[rangeid] = threadid

                self.stack.append(rangeid)

            elif flags == 4: # a range ends
                if rangeid in self.stack:
                    self.stack.pop(self.stack.index(rangeid))
                    if self.tids[rangeid] != threadid:
                        print("error: popping marker from different thread than pushed????\n")
                else:
                    print("error: popping non-existing marker????\n")

            self.next_idx = self.next_idx+1

        return self.cvt_stack_to_string(tid_printing)

def print_grids(gridX, gridY, gridZ, blockX, blockY, blockZ):
    print("({},{},{})\t({},{},{})".format(gridX, gridY, gridZ,
                                          blockX, blockY, blockZ),
          end='\t')

def print_place_ids(streamId, threadId):
    print("{}\t{}".format(streamId, hex(threadId)),
          end='\t')

def print_times(apiStart, apiLatency, gpuStart, gpuLatency):
    print("{}\t{}\t{}\t{}".format(apiStart, apiLatency, gpuStart, gpuLatency),
          end='\t')

###############################################################################
#
# The list of kernel calls
#
###############################################################################
class KernelTable:
    def __init__(self, sqlite_filename, markers, start_time, end_time, args):
        self.filename = sqlite_filename
        self.markers = markers
        self.start_time = start_time
        self.end_time = end_time
        self.args = args
        # We join the concurrent_kernel table with the runtime api call table
        # on correlationId.  We only select records between the start and end
        # of the NVTX __start_profile and __stop_profile
        self.list = do_query(self.filename,
                    '''
                    select
                        kernels._id_,
                        kernels.registersPerThread,
                        kernels.start as kernelStart,
                        kernels.completed as kernelEnd,
                        kernels.deviceId,
                        kernels.contextId,
                        kernels.streamId,
                        kernels.gridX,
                        kernels.gridY,
                        kernels.gridZ,
                        kernels.blockX,
                        kernels.blockY,
                        kernels.blockZ,
                        kernels.staticSharedMemory,
                        kernels.correlationId,
                        api_calls.start as apiStart,
                        api_calls.end as apiEnd,
                        api_calls.processId,
                        api_calls.threadId,
                        StringTable.value as kernelName
                    from cupti_activity_kind_concurrent_kernel as kernels
                    inner join cupti_activity_kind_runtime as api_calls
                        on kernels.correlationId = api_calls.correlationId
                    inner join StringTable
                        on kernels.name = StringTable._id_
                    where apiStart > {start_val} and apiStart < {end_val}
                    order by apiStart'''.format(
                        start_val = self.start_time,
                        end_val   = self.end_time))

    ###########################################################################
    # here we're doing the work that couldn't be done using a simple sql join
    ###########################################################################
    def process_list(self):
        for kernel_call in self.list:
            call_time = kernel_call['apiStart']
            rel_start_time = (kernel_call['kernelStart']-self.start_time)
            execution_time = (kernel_call['kernelEnd'] -
                              kernel_call['kernelStart'])
            thread_id = kernel_call['threadId']
            print_grids(kernel_call['gridX'],
                        kernel_call['gridY'],
                        kernel_call['gridZ'],
                        kernel_call['blockX'],
                        kernel_call['blockY'],
                        kernel_call['blockZ'])
            print_place_ids(kernel_call['streamId'], thread_id)
            print_times(call_time-self.start_time,
                        kernel_call['apiEnd']-call_time,
                        rel_start_time,
                        execution_time)
            # print the markers from just before the kernel's api timestamp
            if self.args.also_markers:
                if self.markers is not None:
                    print(self.markers.update_time(call_time, thread_id), end='\t')
                else:
                    print('', end='\t')

            print(kernel_call['kernelName'])


###############################################################################
#
# The list of memcpys
#
###############################################################################
class MemcpyTable:
    # enums from cupti_activity.h
    memory_kinds = ['UNKNOWN', 'PAGEABLE', 'PINNED', 'DEVICE',
                    'ARRAY', 'MANAGED', 'DEVICE_STATIC', 'MANAGED_STATIC']
    copy_kinds = ['UNKNOWN', 'HTOD', 'DTOH', 'HTOA', 'ATOH', 'ATOA', 'ATOD',
                  'DTOA', 'DTOD', 'HTOH', 'PTOP']

    def __init__(self, sqlite_filename, start_time, end_time, args):
        self.start_time = start_time
        self.end_time = end_time
        # We join the memcpy table with the runtime api call table
        # on correlationId.  We only select records between the start and end
        # of the NVTX __start_profile and __stop_profile
        self.list = do_query(sqlite_filename,
                    '''
                    select
                        memcpy._id_,
                        memcpy.copyKind,
                        memcpy.srcKind,
                        memcpy.dstKind,
                        memcpy.flags,
                        memcpy.bytes,
                        memcpy.start as cpyStart,
                        memcpy.end as cpyEnd,
                        memcpy.correlationId,
                        memcpy.streamId,
                        api_calls.start as apiStart,
                        api_calls.end as apiEnd,
                        api_calls.processId,
                        api_calls.threadId
                    from cupti_activity_kind_memcpy as memcpy
                    inner join cupti_activity_kind_runtime as api_calls
                        on memcpy.correlationId = api_calls.correlationId
                    where apiStart > {start_val} and apiStart < {end_val}
                    order by apiStart'''.format(
                        start_val = start_time,
                        end_val   = end_time))

    ###########################################################################
    # here we're doing the work that couldn't be trivially done using a simple sql join
    ###########################################################################
    def process_list(self):
        for memcpy in self.list:
            call_time = memcpy['apiStart']
            rel_start_time = (memcpy['cpyStart']-self.start_time)
            execution_time = (memcpy['cpyEnd'] -
                              memcpy['cpyStart'])
            print_grids(MemcpyTable.copy_kinds[memcpy['copyKind']],
                        MemcpyTable.memory_kinds[memcpy['srcKind']],
                        MemcpyTable.memory_kinds[memcpy['dstKind']],
                        memcpy['flags'],
                        '', '')
            print_place_ids(memcpy['streamId'], memcpy['threadId'])
            print_times(call_time-self.start_time,
                        memcpy['apiEnd']-call_time,
                        rel_start_time,
                        execution_time)

            # no marker, but memcpy bytes
            print('\tmemcpy - {}'.format(memcpy['bytes']))

###############################################################################
#
# The list of memsets
#
###############################################################################
class MemsetTable:
    # enums from cupti_activity.h
    memory_kinds = ['UNKNOWN', 'PAGEABLE', 'PINNED', 'DEVICE',
                    'ARRAY', 'MANAGED', 'DEVICE_STATIC', 'MANAGED_STATIC']
    copy_kinds = ['UNKNOWN', 'HTOD', 'DTOH', 'HTOA', 'ATOH', 'ATOA', 'ATOD',
                  'DTOA', 'DTOD', 'HTOH', 'PTOP']

    def __init__(self, sqlite_filename, start_time, end_time, args):
        self.start_time = start_time
        self.end_time = end_time
        # We join the memset table with the runtime api call table
        # on correlationId.  We only select records between the start and end
        # of the NVTX __start_profile and __stop_profile
        self.list = do_query(sqlite_filename,
                    '''
                    select
                        memset._id_,
                        memset.value,
                        memset.memoryKind as dstKind,
                        memset.flags,
                        memset.bytes,
                        memset.start as dvcStart,
                        memset.end as dvcEnd,
                        memset.correlationId,
                        memset.streamId,
                        api_calls.start as apiStart,
                        api_calls.end as apiEnd,
                        api_calls.processId,
                        api_calls.threadId
                    from cupti_activity_kind_memset as memset
                    inner join cupti_activity_kind_runtime as api_calls
                        on memset.correlationId = api_calls.correlationId
                    where apiStart > {start_val} and apiStart < {end_val}
                    order by apiStart'''.format(
                        start_val = start_time,
                        end_val   = end_time))

    ###########################################################################
    # here we're doing the work that couldn't be trivially done using a simple sql join
    ###########################################################################
    def process_list(self):
        for memset in self.list:
            call_time = memset['apiStart']
            rel_start_time = (memset['dvcStart']-self.start_time)
            execution_time = (memset['dvcEnd'] -
                              memset['dvcStart'])
            print_grids('',
                        memset['value'],
                        MemsetTable.memory_kinds[memset['dstKind']],
                        memset['flags'],
                        '', '')
            print_place_ids(memset['streamId'], memset['threadId'])
            print_times(call_time-self.start_time,
                        memset['apiEnd']-call_time,
                        rel_start_time,
                        execution_time)
            # no marker, but memset bytes
            print('\tmemset - {}'.format(memset['bytes']))


###############################################################################
#
# The list of synchronizations
#
###############################################################################
class SyncTable:
    # enums from cupti_activity.h
    sync_kinds = ['UNKNOWN', 'EVENT_SYNC', 'STREAM_WAIT_EVENT',
                  'STREAM_SYNC', 'CONTEXT_SYNC']

    def __init__(self, sqlite_filename, start_time, end_time, args):
        self.start_time = start_time
        self.end_time = end_time
        # We join the sync table with the runtime api call table
        # on correlationId.  We only select records between the start and end
        # of the NVTX __start_profile and __stop_profile
        self.list = do_query(sqlite_filename,
                    '''
                    select
                        sync._id_,
                        sync.type,
                        sync.start as dvcStart,
                        sync.end as dvcEnd,
                        sync.correlationId,
                        sync.streamId,
                        api_calls.start as apiStart,
                        api_calls.end as apiEnd,
                        api_calls.processId,
                        api_calls.threadId
                    from cupti_activity_kind_synchronization as sync
                    inner join cupti_activity_kind_runtime as api_calls
                        on sync.correlationId = api_calls.correlationId
                    where apiStart > {start_val} and apiStart < {end_val}
                    order by apiStart'''.format(
                        start_val = start_time,
                        end_val   = end_time))

    ###########################################################################
    # here we're doing the work that couldn't be trivially done using a simple sql join
    ###########################################################################
    def process_list(self):
        for sync in self.list:
            call_time = sync['apiStart']
            rel_start_time = (sync['dvcStart']-self.start_time)
            execution_time = (sync['dvcEnd'] -
                              sync['dvcStart'])
            print_grids('', '', SyncTable.sync_kinds[sync['type']],
                        '', '', '')
            print_place_ids(sync['streamId'], sync['threadId'])
            print_times(call_time-self.start_time,
                        sync['apiEnd']-call_time,
                        rel_start_time,
                        execution_time)
            # no marker
            print('\tsync')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process the output of nvprof --profile-api-trace all.')
    parser.add_argument('input_file', nargs=1,
                        help='.nvvp file to process')
    parser.add_argument('--also-markers', action='store_true',
                        help='print nvtx marker info')

    args = parser.parse_args()

    try:
        markers = MarkerTable(args.input_file[0])
        start_time = markers.first_time
        end_time = markers.last_time
    except:
        markers = None
        start_time = 0
        end_time = 9223372036854775806

    kernels = KernelTable(args.input_file[0], markers, start_time, end_time, args)
    kernels.process_list()
    memcpys = MemcpyTable(args.input_file[0], start_time, end_time, args)
    memcpys.process_list()
    memsets = MemsetTable(args.input_file[0], start_time, end_time, args)
    memsets.process_list()
    syncs = SyncTable(args.input_file[0], start_time, end_time, args)
    syncs.process_list()
