import java.util.ArrayList;

public class SpanTreeSWAP {

	public static boolean SWAP(ArrayList<VertexList> spanning_tree, Edge e1, Edge e2)
	{	
		// Re-initializing subsets
		init(1000);
		// Connecting all edges of Spanning Tree except e1 and e2.
		for (VertexList curr_ver_list : spanning_tree)
		{
			for (Integer adjacent_vertex : curr_ver_list.adjacent_vertices)
			{
				if (!(edgeContainsVertices(e1, curr_ver_list.vertex, adjacent_vertex) ||
					edgeContainsVertices(e2, curr_ver_list.vertex, adjacent_vertex)))
				{
					union(curr_ver_list.vertex, adjacent_vertex);
				}
			}
		}
		
		// Try to add e2
		return (!(find(e2.vertex1) == find(e2.vertex2)));
	}
	
	public static boolean edgeContainsVertices (Edge e, int vertex1, int vertex2)
	{
		return ((vertex1 == e.vertex1 && vertex2 == e.vertex2) ||
				(vertex2 == e.vertex1 && vertex1 == e.vertex2));
	}
	
	public static class VertexList
	{
		public VertexList(int vertex, ArrayList<Integer> adjacent_vertices)
		{
			this.vertex = vertex;
			this.adjacent_vertices = adjacent_vertices;
		}
		
		int vertex;
		ArrayList<Integer> adjacent_vertices = new ArrayList<Integer>();
	}
	
	public static class Edge
	{
		int vertex1;
		int vertex2;
		
		Edge(int vertex1, int vertex2)
		{
			this.vertex1 = vertex1;
			this.vertex2 = vertex2;
		}
	}
	
	// Data structure Disjoint Data Set
	
	static Subset[] subsets = new Subset[1000];
	
	public static void init(int n)
	{
		for (int i = 0; i < n; i++)
		{
			subsets[i] = new Subset();
		}
	}
    
	public static void makeSet(int x)
	{
		subsets[x].parent = x;
		subsets[x].rank = 0;
	}
	
	public static int find(int x)
	{	
		if (subsets[x].parent != x)
			subsets[x].parent = find(subsets[x].parent);
		     
		return subsets[x].parent;
	}
	
	public static void union(int x, int y)
	{
		int x_root = find(x);
    	int y_root = find(y);
    	
    	if (x_root == 0)
    	{
    		makeSet(x);
    		x_root = x;
    	}
    	
    	if (y_root == 0)
    	{
    		makeSet(y);
    		y_root = y;
    	}
    		
    	if (x_root == y_root)
    		return;	

	     // x and y are not already in same set. Merge them.
	     if (subsets[x_root].rank < subsets[y_root].rank)
	         subsets[x_root].parent = y_root;
	     else if (subsets[x_root].rank > subsets[y_root].rank)
	         subsets[y_root].parent = x_root;
	     else
	     {
	    	 subsets[y_root].parent = x_root;
	    	 subsets[x_root].rank = subsets[x_root].rank + 1;
	     }
	}
	
    static class Subset{
    	int parent;
    	int rank;
    }
    
    public static void main(String[] args) 
    {	
		init(1000);
		
		// Test data
		ArrayList<VertexList> st = new ArrayList<VertexList>();
		
		ArrayList<Integer> adj_v = new ArrayList<Integer>();
		adj_v.add(3);
		st.add(new VertexList(1, adj_v));
		st.add(new VertexList(2, adj_v));
		adj_v = new ArrayList<Integer>();
		adj_v.add(1);
		adj_v.add(2);
		adj_v.add(4);
		adj_v.add(6);
		st.add(new VertexList(3, adj_v));
		adj_v = new ArrayList<Integer>();
		adj_v.add(3);
		adj_v.add(5);
		st.add(new VertexList(4, adj_v));
		
		adj_v = new ArrayList<Integer>();
		adj_v.add(4);
		st.add(new VertexList(5, adj_v));
		
		adj_v = new ArrayList<Integer>();
		adj_v.add(3);
		st.add(new VertexList(6, adj_v));
		
		// Case 1
		System.out.println("Case 1");
		if (SWAP(st, new Edge(3, 6), new Edge(2, 6)))
		{
			System.out.println("Edge Swap is Valid");
		}
		else
		{
			System.out.println("Edge swap is Invalid");
		}
		// Case 2
		System.out.println("Case 2");
		if (SWAP(st, new Edge(3, 6), new Edge(3, 5)))
		{
			System.out.println("Edge Swap is Valid");
		}
		else
		{
			System.out.println("Edge swap is Invalid");
		}
		// Case 3
		System.out.println("Case 3");
		if (SWAP(st, new Edge(4, 3), new Edge(1, 5)))
		{
			System.out.println("Edge Swap is Valid");
		}
		else
		{
			System.out.println("Edge swap is Invalid");
		}
		// Case 4
		System.out.println("Case 4");
		if (SWAP(st, new Edge(3, 1), new Edge(2, 1)))
		{
			System.out.println("Edge Swap is Valid");
		}
		else
		{
			System.out.println("Edge swap is Invalid");
		}
		// Case 5
		System.out.println("Case 5");
		if (SWAP(st, new Edge(2, 3), new Edge(5, 6)))
		{
			System.out.println("Edge Swap is Valid");
		}
		else
		{
			System.out.println("Edge swap is Invalid");
		}
	}
}