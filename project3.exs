if length(System.argv()) == 2 do
  [numNodes, max_requests] = System.argv()
  Tapestry.main([numNodes, max_requests])
else
  [numNodes, max_requests, failure_percentage] = System.argv()
  Tapestry.main([numNodes, max_requests, failure_percentage])
end
