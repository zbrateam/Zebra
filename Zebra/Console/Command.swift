//
//  Command.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

fileprivate let finishFileno: Int32 = 3

fileprivate typealias PipeDescriptor = Array<Int32>

fileprivate extension Array where Element == Int32 {
	func close() {
		Darwin.close(self[0])
		Darwin.close(self[1])
	}
}

@objc protocol CommandDelegate: NSObjectProtocol {
	@objc optional func receivedData(_ data: String)
	@objc optional func receivedErrorData(_ data: String)
	@objc optional func receivedFinishData(_ data: String)
}

class Command: NSObject {

	private struct PipeDescriptors {
		var stdOut: PipeDescriptor = [0, 0]
		var stdErr: PipeDescriptor = [0, 0]
		var finish: PipeDescriptor = [0, 0]
	}

	private(set) weak var delegate: CommandDelegate?
	private(set) var command = ""
	private(set) var arguments = [String]()
	private(set) var asRoot = false

	private(set) var output = ""

	var useFinishFd = false {
		didSet { useFinishFdDidChange() }
	}

	private var fds = PipeDescriptors()

	@discardableResult
	@objc class func execute(_ command: String, arguments: [String]?, asRoot: Bool = false) -> String? {
		// As this method is intended for convenience, the arguments array isn’t expected to have the
		// first argument, which is typically the path or name of the binary being invoked. Add it now.
		let task = Command(command: command,
											 arguments: [command] + (arguments ?? []),
											 asRoot: asRoot,
											 delegate: nil)
		return task.execute() == 0 ? task.output : nil
	}

	init(delegate: CommandDelegate?) {
		super.init()
		self.delegate = delegate
	}

	@objc convenience init(command: String, arguments: [String]?, asRoot: Bool = false, delegate: CommandDelegate? = nil) {
		self.init(delegate: delegate)
		self.asRoot = asRoot

		if asRoot {
			// Override to run through supersling instead
			self.command = SlingshotController.superslingPath
			self.arguments = [SlingshotController.superslingPath, command] + (arguments ?? [])
		} else {
			self.command = command
			self.arguments = arguments ?? []
		}
	}

	private func useFinishFdDidChange() {
		let binaryIndex = asRoot ? 1 : 0
		if arguments.count > binaryIndex,
			 arguments[binaryIndex] == "apt" {
				// We need to insert this flag to ensure our fd is passed through to dpkg.
			let flag = String(format: "-oAPT::Keep-Fds::=%d", finishFileno)
			if useFinishFd {
				arguments.insert(flag, at: min(binaryIndex + 1, arguments.count))
			} else if let index = arguments.firstIndex(of: flag) {
				arguments.remove(at: index)
			}
		}
	}

	@objc func execute() -> Int32 {
		// Create output and error pipes
		guard pipe(&fds.stdOut) != -1,
					pipe(&fds.stdErr) != -1 else {
			return errno
		}

		if useFinishFd {
			guard pipe(&fds.finish) != -1 else {
				return errno
			}
		}
		
		// Convert our arguments array from Strings to char pointers
		let argv = arguments.cStringArray
		
		// Construct environment vars
		var environment = [
			"PATH=\(Device.path)"
		]

		if useFinishFd {
			// $CYDIA enables maintenance scripts to send “finish” messages to the
			// package manager. Contains two integers. First is the fd to write to,
			// second is the API version (currently 1).
			environment.append(String(format: "CYDIA=%d 1", finishFileno))
		}
		
		// Convert our environment array from NSStrings to char pointers
		let envp = arguments.cStringArray
		
		// Create our file actions to read data back from posix_spawn
		var actions: posix_spawn_file_actions_t!
		posix_spawn_file_actions_init(&actions);
		posix_spawn_file_actions_addclose(&actions, fds.stdOut[0])
		posix_spawn_file_actions_addclose(&actions, fds.stdErr[0])
		posix_spawn_file_actions_adddup2(&actions, fds.stdOut[1], STDOUT_FILENO)
		posix_spawn_file_actions_adddup2(&actions, fds.stdErr[1], STDERR_FILENO)
		posix_spawn_file_actions_addclose(&actions, fds.stdOut[1])
		posix_spawn_file_actions_addclose(&actions, fds.stdErr[1])
		
		if useFinishFd {
			posix_spawn_file_actions_addclose(&actions, fds.finish[0])
			posix_spawn_file_actions_adddup2(&actions, fds.finish[1], finishFileno)
			posix_spawn_file_actions_addclose(&actions, fds.finish[1])
		}
		
		// Setup the dispatch queues for reading output and errors
		let lock = DispatchSemaphore(value: 0)
		let readQueue = DispatchQueue(label: "xyz.willy.Zebra.david", attributes: .concurrent)
		
		// Setup the dispatch handler for the output pipes
		let stdOutSource = DispatchSource.makeReadSource(fileDescriptor: fds.stdOut[0], queue: readQueue)
		let stdErrSource = DispatchSource.makeReadSource(fileDescriptor: fds.stdErr[0], queue: readQueue)
		var finishSource: DispatchSourceRead?

		if useFinishFd {
			finishSource = DispatchSource.makeReadSource(fileDescriptor: fds.finish[0], queue: readQueue)
		}

		let handleSourceEvent = { (source: DispatchSourceRead, fd: Int32, action: @escaping (String) -> ()) in
			let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(BUFSIZ))
			let bytes = read(fd, buffer, Int(BUFSIZ))
			if bytes > 0 {
				// Read from output and notify delegate
				let string = String(cString: buffer)
				action(string)
			} else {
				// The fd was closed; cancel the dispatch_source.
				source.cancel()
			}
			free(buffer)
		}

		stdOutSource.setEventHandler {
			handleSourceEvent(stdOutSource, self.fds.stdOut[0]) { result in
				self.delegate?.receivedData?(result)
				self.output += result
			}
		}
		stdErrSource.setEventHandler {
			handleSourceEvent(stdOutSource, self.fds.stdErr[0]) { result in
				self.delegate?.receivedErrorData?(result)
				self.output += result
			}
		}
		finishSource?.setEventHandler {
			handleSourceEvent(finishSource!, self.fds.finish[0]) { result in
				self.delegate?.receivedFinishData?(result)
			}
		}

		stdOutSource.setCancelHandler {
			close(self.fds.stdOut[0])
			lock.signal()
		}
		stdErrSource.setCancelHandler {
			close(self.fds.stdErr[0])
			lock.signal()
		}
		finishSource?.setCancelHandler {
			// Finish fd isn’t expected to be closed, so no semaphore involved here.
			close(self.fds.finish[0])
		}

		// Activate the dispatch sources
		stdOutSource.resume()
		stdErrSource.resume()
		finishSource?.resume()

		// Spawn the child process
		var pid = pid_t()
		let commandCString = command.cString!
		let spawnResult = posix_spawnp(&pid, commandCString, &actions, nil, argv, envp)
		argv.free()
		envp.free()
		free(commandCString)

		if spawnResult < 0 {
			fds.stdOut.close()
			fds.stdErr.close()
			if useFinishFd {
				fds.finish.close()
			}
			return spawnResult
		}

		// Close the write ends of the pipes so no odd data comes through them
		close(fds.stdOut[1])
		close(fds.stdErr[1])

		// We need to wait twice, once for the output handler and once for the error handler
		lock.wait()
		lock.wait()

		// Waits for the child process to terminate
		var status = Int32()
		waitpid(pid, &status, 0)

		// The finish fd is unlikely to have closed on its own, so close it now.
		if let finishSource = finishSource,
			 !finishSource.isCancelled {
			finishSource.cancel()
		}

		// Get the true status code, if the process exited normally. If it died for some other reason,
		// we return the actual value we got back from waitpid(3), which should still be useful for
		// debugging what went wrong.
		return WIFEXITED(status) ? WEXITSTATUS(status) : status
	}

}
