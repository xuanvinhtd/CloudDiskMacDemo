//
//  HCDLocalRawEvent.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/16/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDLocalRawEvent {
    
    static func flagsFromRaw(v1: UInt32) -> Set<KFSEventStreamEventFlag> {
        var	a1	=   Set<KFSEventStreamEventFlag>()
        for i:UInt32 in 0..<18 {
            let	v2	=	0b01 << i
            let	ok	=	(v2 & v1) > 0
            if ok {
                let	s	=	KFSEventStreamEventFlag(rawValue: v2)
                if  s   !=  nil {
                    a1.insert(s!)
                } else {
                    print("s !nil at value: \(s)")
                }
            }
        }
        return a1
    }
    
    static func stringFromFlag(flag: KFSEventStreamEventFlag?) -> String {
        guard let flag = flag else { return "????" }
        
        switch (flag) {
            
        case .None:				return	"None";
        case .MustScanSubDirs:	return	"MustScanSubDirs";
        case .UserDropped:		return	"UserDropped";
        case .KernelDropped:	return	"KernelDropped";
        case .EventIdsWrapped:	return	"EventIdsWrapped";
        case .HistoryDone:		return	"HistoryDone";
        case .RootChanged:		return	"RootChanged";
        case .Mount:			return	"Mount";
            
        case .Unmount:			return	"Unmount";
        case .ItemCreated:		return	"ItemCreated";
        case .ItemRemoved:		return	"ItemRemoved";
        case .ItemInodeMetaMod:	return	"ItemInodeMetaMod";
        case .ItemRenamed:		return	"ItemRenamed";
        case .ItemModified:		return	"ItemModified";
        case .ItemFinderInfoMod:return	"ItemFinderInfoMod";
        case .ItemChangeOwner:	return	"ItemChangeOwner";
        case .ItemXattrMod:		return	"ItemXattrMod";
        case .ItemIsFile:		return	"ItemIsFile";
        case .ItemIsDir:		return	"ItemIsDir";
        case .ItemIsSymlink:	return	"ItemIsSymlink";
        case .OwnEvent:			return	"OwnEvent";
            
        default:                return	"????";
        }
    }
    
    static func stringFromFlags(flags: Set<KFSEventStreamEventFlag>) -> String {
        let flagStrings = Array(flags).map{ self.stringFromFlag(flag: $0) }
        return flagStrings.joined(separator: "|")
    }
    
    let path: String
    let name: String
    let flagRaw: UInt32
    let flags: Set<KFSEventStreamEventFlag>
    let ID: UInt64
    let flagString: String
    let shouldBeSkipped: Bool
    
    init(path: String, flagInt: UInt32, ID: UInt64) {
        let name = path.lastPathComponent
        self.name = name
        self.path = path
        self.ID = ID
        
        self.flagRaw = flagInt
        let flags = HCDLocalRawEvent.flagsFromRaw(v1: flagInt)
        self.flags = flags
        self.flagString = HCDLocalRawEvent.stringFromFlags(flags: flags)
        self.shouldBeSkipped = HCDGlobalDefine.FileName.shouldIgnoreFile(hasName: name)
    }
    
    func containFlag(flag: KFSEventStreamEventFlag) -> Bool {
        return self.flags.contains(flag)
    }
    
    func containOnlyFlag(flag: KFSEventStreamEventFlag) -> Bool {
        //NOTE: DON'T USE THIS FOR CHECK .ItemIsFile or .ItemIsDir ! I JUST DON'T WANT TO PUT A GUARD HERE
        return self.flags.contains(flag) && self.flags.count < 3
    }

    func description() -> String {
        return "\(ID) - \(flagRaw):\(flagString) - \(path)"
    }
}

enum KFSEventStreamEventFlag: UInt32 {
    
    /*
     * There was some change in the directory at the specific path
     * supplied in this event.
     */
    case None = 0x00000000,
    
    /*
     * Your application must rescan not just the directory given in the
     * event, but all its children, recursively. This can happen if there
     * was a problem whereby events were coalesced hierarchically. For
     * example, an event in /Users/jsmith/Music and an event in
     * /Users/jsmith/Pictures might be coalesced into an event with this
     * flag set and path=/Users/jsmith. If this flag is set you may be
     * able to get an idea of whether the bottleneck happened in the
     * kernel (less likely) or in your client (more likely) by checking
     * for the presence of the informational flags
     * UserDropped or
     * KernelDropped.
     */
    MustScanSubDirs = 0x00000001,
    
    /*
     * The UserDropped or
     * KernelDropped flags may be set in addition
     * to the MustScanSubDirs flag to indicate
     * that a problem occurred in buffering the events (the particular
     * flag set indicates where the problem occurred) and that the client
     * must do a full scan of any directories (and their subdirectories,
     * recursively) being monitored by this stream. If you asked to
     * monitor multiple paths with this stream then you will be notified
     * about all of them. Your code need only check for the
     * MustScanSubDirs flag; these flags (if
     * present) only provide information to help you diagnose the problem.
     */
    UserDropped = 0x00000002,
    KernelDropped = 0x00000004,
    
    /*
     * If EventIdsWrapped is set, it means the
     * 64-bit event ID counter wrapped around. As a result,
     * previously-issued event ID's are no longer valid arguments for the
     * sinceWhen parameter of the FSEventStreamCreate...() functions.
     */
    EventIdsWrapped = 0x00000008,
    
    /*
     * Denotes a sentinel event sent to mark the end of the "historical"
     * events sent as a result of specifying a sinceWhen value in the
     * FSEventStreamCreate...() call that created this event stream. (It
     * will not be sent if KFSEventStreamEventIdSinceNow was passed for
     * sinceWhen.) After invoking the client's callback with all the
     * "historical" events that occurred before now, the client's
     * callback will be invoked with an event where the
     * HistoryDone flag is set. The client should
     * ignore the path supplied in this callback.
     */
    HistoryDone = 0x00000010,
    
    /*
     * Denotes a special event sent when there is a change to one of the
     * directories along the path to one of the directories you asked to
     * watch. When this flag is set, the event ID is zero and the path
     * corresponds to one of the paths you asked to watch (specifically,
     * the one that changed). The path may no longer exist because it or
     * one of its parents was deleted or renamed. Events with this flag
     * set will only be sent if you passed the flag
     * KFSEventStreamCreateFlagWatchRoot to FSEventStreamCreate...() when
     * you created the stream.
     */
    RootChanged = 0x00000020,
    
    /*
     * Denotes a special event sent when a volume is mounted underneath
     * one of the paths being monitored. The path in the event is the
     * path to the newly-mounted volume. You will receive one of these
     * notifications for every volume mount event inside the kernel
     * (independent of DiskArbitration). Beware that a newly-mounted
     * volume could contain an arbitrarily large directory hierarchy.
     * Avoid pitfalls like triggering a recursive scan of a non-local
     * filesystem, which you can detect by checking for the absence of
     * the MNT_LOCAL flag in the f_flags returned by statfs(). Also be
     * aware of the MNT_DONTBROWSE flag that is set for volumes which
     * should not be displayed by user interface elements.
     */
    Mount  = 0x00000040,
    
    /*
     * Denotes a special event sent when a volume is unmounted underneath
     * one of the paths being monitored. The path in the event is the
     * path to the directory from which the volume was unmounted. You
     * will receive one of these notifications for every volume unmount
     * event inside the kernel. This is not a substitute for the
     * notifications provided by the DiskArbitration framework; you only
     * get notified after the unmount has occurred. Beware that
     * unmounting a volume could uncover an arbitrarily large directory
     * hierarchy, although Mac OS X never does that.
     */
    Unmount = 0x00000080,
    
    /*
     * A file system object was created at the specific path supplied in this event.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemCreated = 0x00000100,
    
    /*
     * A file system object was removed at the specific path supplied in this event.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemRemoved = 0x00000200,
    
    /*
     * A file system object at the specific path supplied in this event had its metadata modified.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemInodeMetaMod = 0x00000400,
    
    /*
     * A file system object was renamed at the specific path supplied in this event.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemRenamed = 0x00000800,
    
    /*
     * A file system object at the specific path supplied in this event had its data modified.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemModified = 0x00001000,
    
    /*
     * A file system object at the specific path supplied in this event had its FinderInfo data modified.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemFinderInfoMod = 0x00002000,
    
    /*
     * A file system object at the specific path supplied in this event had its ownership changed.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemChangeOwner = 0x00004000,
    
    /*
     * A file system object at the specific path supplied in this event had its extended attributes modified.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemXattrMod = 0x00008000,
    
    /*
     * The file system object at the specific path supplied in this event is a regular file.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemIsFile = 0x00010000,
    
    /*
     * The file system object at the specific path supplied in this event is a directory.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemIsDir = 0x00020000,
    
    /*
     * The file system object at the specific path supplied in this event is a symbolic link.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemIsSymlink = 0x00040000,
    
    /*
     * Indicates the event was triggered by the current process.
     * (This flag is only ever set if you specified the MarkSelf flag when creating the stream.)
     */
    OwnEvent = 0x00080000,
    
    /*
     * Indicates the object at the specified path supplied in this event is a hard link.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemIsHardlink = 0x00100000,
    
    /* Indicates the object at the specific path supplied in this event was the last hard link.
     * (This flag is only ever set if you specified the FileEvents flag when creating the stream.)
     */
    ItemIsLastHardlink = 0x00200000
    
    func toString() -> String {
        return HCDLocalRawEvent.stringFromFlag(flag: self)
    }
}
