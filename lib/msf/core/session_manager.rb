module Msf

###
#
# SessionManager
# --------------
#
# The purpose of the session manager is to keep track of sessions that are
# created during the course of a framework instance's lifetime.  When
# exploits succeed, the payloads they use will create a session object,
# where applicable, there will implement zero or more of the core
# supplied interfaces for interacting with that session.  For instance,
# if the payload supports reading and writing from an executed process,
# the session would implement SimpleCommandShell in a method that is
# applicable to the way that the command interpreter is communicated 
# with.
#
###
class SessionManager

	include Enumerable

	def initialize(framework)
		self.framework = framework
		self.sessions  = {}
		self.sid_pool  = 0
	end

	#
	# Returns the session object that is associated with the supplied sid
	#
	def [](sid)
		return get(sid)
	end

	#
	# Register the supplied session
	#
	def <<(session)
		return register(session)
	end

	#
	# Implement for Enumerable
	#
	def each(&block)
		sessions.each(&block)
	end

	#
	# Registers the supplied session object with the framework and returns
	# a unique session identifier to the caller.
	#
	def register(session)
		if (session.sid)
			wlog("registered session passed to register again (sid #{session.sid}).")
			return nil
		end

		next_sid = (self.sid_pool += 1)

		# Insert the session into the session hash table
		sessions[next_sid] = session

		# Initialize the session's sid and framework instance pointer
		session.sid       = next_sid
		session.framework = framework
	
		# Notify the framework that we have a new session opening up...
		framework.events.on_session_open(session)

		return next_sid
	end

	#
	# Deregisters the supplied session object with the framework
	#
	def deregister(session)
		# Tell the framework that we have a parting session
		framework.events.on_session_close(session)

		# Remove it from the hash
		sessions.delete(session.sid)

		# Close it down
		session.cleanup
	end

	#
	# Returns the session associated with the supplied sid, if any
	#
	def get(sid)
		return sessions[sid]
	end

protected
	
	attr_accessor :sid_pool, :sessions, :framework

end

end
