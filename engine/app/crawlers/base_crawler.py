import abc
import logging
from typing import List, Dict, Any
from engine.app.discovery.source_registry import RegisteredSource

logger = logging.getLogger("rexam.crawler")

class BaseCrawler(abc.ABC):
    def __init__(self, source: RegisteredSource):
        self.source = source

    @abc.abstractmethod
    async def discover_notices(self) -> List[Dict[str, Any]]:
        """
        Discovers active examination notices, returning a list of dicts with:
        - title: str
        - notice_url: str
        - pdf_url: Optional[str]
        - date_posted: Optional[str]
        - context: Dict[str, Any]
        """
        pass

