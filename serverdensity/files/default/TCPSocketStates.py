# tcpsocketstates - TCP Socket Status Graph for Server Density
import re
from subprocess import check_output


class TCPSocketStates:
    def __init__(self, agentConfig, checksLogger):
        self.agentConfig = agentConfig
        self.checksLogger = checksLogger
        pattern = 'TCP:   ([\d]+) \(estab ([\d]+), closed ([\d]+), orphaned ([\d]+), synrecv ([\d]+), timewait ([\d]+)/0\), ports ([\d]+)'
        self.compiled = re.compile(pattern)

    def run(self):
        line = check_output(['ss', '-s']).split('\n')[1]
        data = {
            'total': 0,
            'established': 0,
            'closed': 0,
            'orphaned': 0,
            'synrecv': 0,
            'timewait': 0,
            'ports': 0
        }
        result = self.compiled.match(line)
        return dict(zip(data, result.groups()))
